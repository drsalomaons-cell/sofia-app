-- Business-rule hardening and actor-ID compatibility for 001_sofia_core.
-- Apply only to Neon branch staging-migracao.

DROP FUNCTION ledger_apply(TEXT,TEXT,UUID,JSONB,JSONB);

CREATE FUNCTION ledger_apply(p_key TEXT, p_kind TEXT, p_by TEXT, p_meta JSONB, p_moves JSONB)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_tx UUID;
  v_existing JSONB;
  v_payload JSONB;
  v_move JSONB;
  v_acc UUID;
  v_amt BIGINT;
  v_bal BIGINT;
  v_currency TEXT;
BEGIN
  IF p_key IS NULL OR length(btrim(p_key)) NOT BETWEEN 1 AND 128 THEN
    RAISE EXCEPTION 'invalid idempotency key';
  END IF;
  IF p_kind IS NULL OR length(btrim(p_kind)) = 0 THEN
    RAISE EXCEPTION 'transaction kind is required';
  END IF;
  IF p_moves IS NULL OR jsonb_typeof(p_moves) IS DISTINCT FROM 'array' OR jsonb_array_length(p_moves) < 2 THEN
    RAISE EXCEPTION 'at least two ledger moves are required';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_moves) AS x(value)
    WHERE jsonb_typeof(x.value) IS DISTINCT FROM 'object'
       OR NOT (x.value ? 'account_id')
       OR NOT (x.value ? 'amount')
       OR (x.value->>'amount')::BIGINT = 0
  ) THEN
    RAISE EXCEPTION 'each move requires account_id and non-zero amount';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_moves) AS x(value)
    GROUP BY (x.value->>'account_id')::UUID
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'duplicate account in ledger moves';
  END IF;

  SELECT jsonb_build_object(
    'kind', p_kind,
    'created_by', p_by,
    'moves', jsonb_agg(
      jsonb_build_object(
        'account_id', (x.value->>'account_id')::UUID,
        'amount', (x.value->>'amount')::BIGINT
      ) ORDER BY (x.value->>'account_id')::UUID
    )
  )
  INTO v_payload
  FROM jsonb_array_elements(p_moves) AS x(value);

  INSERT INTO ledger_transactions(idempotency_key,kind,created_by,request_payload,meta)
  VALUES (p_key,p_kind,p_by,v_payload,COALESCE(p_meta,'{}'::jsonb))
  ON CONFLICT (idempotency_key) DO NOTHING
  RETURNING id INTO v_tx;

  IF v_tx IS NULL THEN
    SELECT id,request_payload INTO v_tx,v_existing
    FROM ledger_transactions
    WHERE idempotency_key = p_key;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'idempotency conflict; retry transaction';
    END IF;
    IF v_existing IS DISTINCT FROM v_payload THEN
      RAISE EXCEPTION 'idempotency key reused with a different financial payload';
    END IF;
    RETURN v_tx;
  END IF;

  FOR v_move IN
    SELECT x.value
    FROM jsonb_array_elements(p_moves) AS x(value)
    ORDER BY (x.value->>'account_id')::UUID
  LOOP
    v_acc := (v_move->>'account_id')::UUID;
    v_amt := (v_move->>'amount')::BIGINT;
    UPDATE ledger_accounts
       SET balance = balance + v_amt,
           version = version + 1,
           updated_at = now()
     WHERE id = v_acc
       AND (is_system OR balance + v_amt >= 0)
     RETURNING balance,currency INTO v_bal,v_currency;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'account missing or insufficient funds: %',v_acc;
    END IF;
    INSERT INTO ledger_entries(transaction_id,account_id,amount,balance_after)
    VALUES (v_tx,v_acc,v_amt,v_bal);
  END LOOP;

  IF EXISTS (
    SELECT a.currency
    FROM ledger_entries e
    JOIN ledger_accounts a ON a.id = e.account_id
    WHERE e.transaction_id = v_tx
    GROUP BY a.currency
    HAVING sum(e.amount) <> 0
  ) THEN
    RAISE EXCEPTION 'unbalanced ledger transaction by currency';
  END IF;
  RETURN v_tx;
END;
$$;;

ALTER TABLE wallets ADD CONSTRAINT wallets_id_user_uq UNIQUE (id,user_id);

ALTER TABLE ledger_accounts ADD CONSTRAINT ledger_accounts_id_owner_uq UNIQUE (id,owner_user_id);

ALTER TABLE ledger_accounts ADD CONSTRAINT ledger_accounts_wallet_owner_fk FOREIGN KEY (wallet_id,owner_user_id) REFERENCES wallets(id,user_id) ON DELETE RESTRICT;

ALTER TABLE withdrawal_requests ADD CONSTRAINT withdrawal_account_owner_fk FOREIGN KEY (debit_account_id,user_id) REFERENCES ledger_accounts(id,owner_user_id) ON DELETE RESTRICT;

ALTER TABLE withdrawal_requests ADD COLUMN ledger_transaction_id UUID UNIQUE REFERENCES ledger_transactions(id) ON DELETE RESTRICT;

ALTER TABLE payments ADD COLUMN ledger_transaction_id UUID UNIQUE REFERENCES ledger_transactions(id) ON DELETE RESTRICT;

ALTER TABLE store_item_prices DROP CONSTRAINT store_item_prices_currency_check;

ALTER TABLE store_item_prices ADD CONSTRAINT store_item_prices_currency_check CHECK (currency IN ('COIN_PURCHASED','COIN_GIFT','BRL_CENTS','USD_CENTS'));

ALTER TABLE events ADD CONSTRAINT events_lucky_gift_age_check CHECK (event_type <> 'lucky_gift' OR minimum_age >= 18);

ALTER TABLE gift_catalog ADD CONSTRAINT gift_catalog_lucky_share_check CHECK (NOT lucky_gift OR platform_share_bps IS NOT DISTINCT FROM 7000);

ALTER TABLE agency_memberships ADD CONSTRAINT agency_memberships_no_reseller_role_check CHECK (role_code <> 'reseller');

ALTER TABLE host_cycles ADD CONSTRAINT host_cycles_fortnight_period_check CHECK ((extract(day FROM period_start)=1 AND period_end=period_start+14) OR (extract(day FROM period_start)=16 AND period_end=(date_trunc('month',period_start::timestamp)+interval '1 month - 1 day')::date));

CREATE FUNCTION guard_store_item_price_currency() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_item_type TEXT; v_lucky BOOLEAN;
BEGIN
  IF NEW.currency = 'COIN_GIFT' THEN
    SELECT i.item_type, COALESCE(g.lucky_gift,TRUE)
      INTO v_item_type,v_lucky
      FROM store_items i LEFT JOIN gift_catalog g ON g.item_id=i.id
     WHERE i.id=NEW.item_id;
    IF NOT FOUND OR v_item_type <> 'gift' OR v_lucky THEN
      RAISE EXCEPTION 'COIN_GIFT may be used only for ordinary gifts';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER store_item_price_currency_guard BEFORE INSERT OR UPDATE ON store_item_prices FOR EACH ROW EXECUTE FUNCTION guard_store_item_price_currency();

CREATE FUNCTION guard_lucky_gift_catalog() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.lucky_gift THEN
    IF NEW.platform_share_bps IS DISTINCT FROM 7000 THEN
      RAISE EXCEPTION 'lucky gift platform share must be 7000 basis points';
    END IF;
    IF EXISTS (SELECT 1 FROM store_item_prices WHERE item_id=NEW.item_id AND currency='COIN_GIFT') THEN
      RAISE EXCEPTION 'lucky gifts cannot be priced in COIN_GIFT';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER lucky_gift_catalog_guard BEFORE INSERT OR UPDATE ON gift_catalog FOR EACH ROW EXECUTE FUNCTION guard_lucky_gift_catalog();

CREATE FUNCTION guard_reseller_agency_membership() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM resellers r WHERE r.user_id=NEW.user_id AND r.status='active')
     AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id=NEW.user_id AND ur.role_code IN ('admin_official','super_admin')) THEN
    RAISE EXCEPTION 'ordinary active reseller cannot join an agency';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER reseller_agency_membership_guard BEFORE INSERT OR UPDATE ON agency_memberships FOR EACH ROW EXECUTE FUNCTION guard_reseller_agency_membership();

CREATE FUNCTION guard_reseller_activation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status='active'
     AND EXISTS (SELECT 1 FROM agency_memberships am WHERE am.user_id=NEW.user_id AND am.status='active')
     AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id=NEW.user_id AND ur.role_code IN ('admin_official','super_admin')) THEN
    RAISE EXCEPTION 'ordinary reseller cannot be an active agency member';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER reseller_activation_guard BEFORE INSERT OR UPDATE ON resellers FOR EACH ROW EXECUTE FUNCTION guard_reseller_activation();
