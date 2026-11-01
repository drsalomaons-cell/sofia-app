-- Reverses 002_business_rule_guards.up.sql and restores migration 001 state.

DROP TRIGGER IF EXISTS reseller_activation_guard ON resellers;

DROP FUNCTION IF EXISTS guard_reseller_activation();

DROP TRIGGER IF EXISTS reseller_agency_membership_guard ON agency_memberships;

DROP FUNCTION IF EXISTS guard_reseller_agency_membership();

DROP TRIGGER IF EXISTS lucky_gift_catalog_guard ON gift_catalog;

DROP FUNCTION IF EXISTS guard_lucky_gift_catalog();

DROP TRIGGER IF EXISTS store_item_price_currency_guard ON store_item_prices;

DROP FUNCTION IF EXISTS guard_store_item_price_currency();

ALTER TABLE host_cycles DROP CONSTRAINT host_cycles_fortnight_period_check;

ALTER TABLE agency_memberships DROP CONSTRAINT agency_memberships_no_reseller_role_check;

ALTER TABLE gift_catalog DROP CONSTRAINT gift_catalog_lucky_share_check;

ALTER TABLE events DROP CONSTRAINT events_lucky_gift_age_check;

ALTER TABLE store_item_prices DROP CONSTRAINT store_item_prices_currency_check;

ALTER TABLE store_item_prices ADD CONSTRAINT store_item_prices_currency_check CHECK (currency IN ('COIN_PURCHASED','COIN_GIFT','DIAMOND','BRL_CENTS','USD_CENTS'));

ALTER TABLE payments DROP COLUMN ledger_transaction_id;

ALTER TABLE withdrawal_requests DROP COLUMN ledger_transaction_id;

ALTER TABLE withdrawal_requests DROP CONSTRAINT withdrawal_account_owner_fk;

ALTER TABLE ledger_accounts DROP CONSTRAINT ledger_accounts_wallet_owner_fk;

ALTER TABLE ledger_accounts DROP CONSTRAINT ledger_accounts_id_owner_uq;

ALTER TABLE wallets DROP CONSTRAINT wallets_id_user_uq;

DROP FUNCTION ledger_apply(TEXT,TEXT,TEXT,JSONB,JSONB);

CREATE FUNCTION ledger_apply(p_key TEXT, p_kind TEXT, p_by UUID, p_meta JSONB, p_moves JSONB)
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
$$;
