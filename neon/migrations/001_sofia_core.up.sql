-- SOFIA consolidated schema, PostgreSQL 18. Apply only to Neon branch staging-migracao.
-- Monetary amounts are integer minor units; all balance mutations must use ledger_apply().

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT,
  phone TEXT,
  password_hash TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','banned','pending')),
  country_code CHAR(2),
  gender TEXT,
  birth_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX users_email_lower_uq ON users (lower(email)) WHERE email IS NOT NULL;

CREATE TABLE user_profiles (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  gallery JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(gallery) = 'array'),
  region TEXT,
  profile_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE roles (
  code TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  hierarchy SMALLINT NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_code TEXT NOT NULL REFERENCES roles(code) ON DELETE RESTRICT,
  scope_type TEXT NOT NULL DEFAULT 'global',
  scope_id TEXT NOT NULL DEFAULT '',
  granted_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role_code, scope_type, scope_id)
);

CREATE TABLE agencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  parent_agency_id UUID REFERENCES agencies(id) ON DELETE SET NULL,
  tier_code TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
  region TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE agency_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_code TEXT NOT NULL REFERENCES roles(code) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (agency_id, user_id, role_code)
);

CREATE TABLE host_profiles (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  agency_id UUID REFERENCES agencies(id) ON DELETE SET NULL,
  host_level INTEGER NOT NULL DEFAULT 0 CHECK (host_level >= 0),
  host_points BIGINT NOT NULL DEFAULT 0 CHECK (host_points >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','disbanded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE family_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_code TEXT NOT NULL DEFAULT 'member' CHECK (role_code IN ('owner','leader','member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (family_id, user_id)
);

CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','frozen','closed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE rooms (
  id TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  agency_id UUID REFERENCES agencies(id) ON DELETE SET NULL,
  family_id UUID REFERENCES families(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  room_type TEXT NOT NULL DEFAULT 'voice' CHECK (room_type IN ('voice','video')),
  region TEXT,
  cover_url TEXT,
  chair_count SMALLINT NOT NULL DEFAULT 8 CHECK (chair_count BETWEEN 4 AND 30),
  visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public','private','invite_only')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','closed','suspended')),
  room_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE room_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  member_role TEXT NOT NULL DEFAULT 'participant' CHECK (member_role IN ('owner','moderator','participant')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX room_memberships_current_uq ON room_memberships(room_id,user_id) WHERE left_at IS NULL;

CREATE TABLE room_seats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  seat_index SMALLINT NOT NULL CHECK (seat_index >= 0),
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  is_muted BOOLEAN NOT NULL DEFAULT FALSE,
  is_locked BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (room_id, seat_index)
);

CREATE UNIQUE INDEX room_seats_user_uq ON room_seats(room_id,user_id) WHERE user_id IS NOT NULL;

CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT REFERENCES rooms(id) ON DELETE SET NULL,
  created_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('lucky_gift','opening','ranking','aristocracy','pk','room_goal','other')),
  name TEXT NOT NULL,
  minimum_age SMALLINT NOT NULL DEFAULT 0 CHECK (minimum_age BETWEEN 0 AND 120),
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','scheduled','active','completed','cancelled')),
  rules JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);

CREATE TABLE store_items (
  id TEXT PRIMARY KEY,
  item_type TEXT NOT NULL CHECK (item_type IN ('gift','frame','entry_effect','vip','aristocracy','photo','game','other')),
  name TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE store_item_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id TEXT NOT NULL REFERENCES store_items(id) ON DELETE CASCADE,
  currency TEXT NOT NULL CHECK (currency IN ('COIN_PURCHASED','COIN_GIFT','DIAMOND','BRL_CENTS','USD_CENTS')),
  amount BIGINT NOT NULL CHECK (amount >= 0),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (item_id, currency)
);

CREATE TABLE gift_catalog (
  item_id TEXT PRIMARY KEY REFERENCES store_items(id) ON DELETE CASCADE,
  gift_tier TEXT,
  platform_share_bps INTEGER CHECK (platform_share_bps BETWEEN 0 AND 10000),
  lucky_gift BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE frame_catalog (
  item_id TEXT PRIMARY KEY REFERENCES store_items(id) ON DELETE CASCADE,
  rarity TEXT,
  duration_days INTEGER CHECK (duration_days IS NULL OR duration_days > 0),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE user_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES store_items(id) ON DELETE RESTRICT,
  quantity BIGINT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  source TEXT NOT NULL DEFAULT 'purchase',
  UNIQUE (user_id, item_id, source, acquired_at)
);

CREATE TABLE event_chances (
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES store_items(id) ON DELETE RESTRICT,
  weight_bps INTEGER NOT NULL CHECK (weight_bps BETWEEN 1 AND 10000),
  max_hits BIGINT CHECK (max_hits IS NULL OR max_hits >= 0),
  PRIMARY KEY (event_id, item_id)
);

CREATE TABLE ledger_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID REFERENCES wallets(id) ON DELETE RESTRICT,
  owner_user_id TEXT REFERENCES users(id) ON DELETE RESTRICT,
  currency TEXT NOT NULL CHECK (currency IN ('COIN_PURCHASED','COIN_GIFT','DIAMOND','BRL_CENTS','USD_CENTS')),
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  balance BIGINT NOT NULL DEFAULT 0,
  version BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (is_system OR balance >= 0),
  CHECK (
    (is_system AND wallet_id IS NULL AND owner_user_id IS NULL)
    OR
    (NOT is_system AND wallet_id IS NOT NULL AND owner_user_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX ledger_accounts_owner_currency_uq ON ledger_accounts(owner_user_id,currency) WHERE owner_user_id IS NOT NULL;

CREATE UNIQUE INDEX ledger_accounts_system_currency_uq ON ledger_accounts(currency) WHERE is_system;

CREATE TABLE ledger_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key TEXT NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 1 AND 128),
  kind TEXT NOT NULL,
  created_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  request_payload JSONB NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ledger_entries (
  id BIGSERIAL PRIMARY KEY,
  transaction_id UUID NOT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  account_id UUID NOT NULL REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
  amount BIGINT NOT NULL CHECK (amount <> 0),
  balance_after BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ledger_entries_account_idx ON ledger_entries(account_id,id);

CREATE INDEX ledger_entries_transaction_idx ON ledger_entries(transaction_id);

CREATE FUNCTION ledger_forbid_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ledger records are immutable';
END;
$$;

CREATE TRIGGER ledger_entries_immutable BEFORE UPDATE OR DELETE ON ledger_entries FOR EACH ROW EXECUTE FUNCTION ledger_forbid_change();

CREATE TRIGGER ledger_transactions_immutable BEFORE UPDATE OR DELETE ON ledger_transactions FOR EACH ROW EXECUTE FUNCTION ledger_forbid_change();

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

CREATE TABLE gift_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  recipient_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  room_id TEXT REFERENCES rooms(id) ON DELETE SET NULL,
  gift_item_id TEXT NOT NULL REFERENCES gift_catalog(item_id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  price_currency TEXT NOT NULL CHECK (price_currency IN ('COIN_PURCHASED','COIN_GIFT')),
  price_amount BIGINT NOT NULL CHECK (price_amount > 0),
  recipient_amount BIGINT NOT NULL DEFAULT 0 CHECK (recipient_amount >= 0),
  ledger_transaction_id UUID NOT NULL UNIQUE REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  debit_account_id UUID NOT NULL REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
  idempotency_key TEXT NOT NULL UNIQUE,
  debit_currency TEXT NOT NULL DEFAULT 'DIAMOND' CHECK (debit_currency = 'DIAMOND'),
  debit_amount BIGINT NOT NULL CHECK (debit_amount > 0),
  requested_brl_cents BIGINT NOT NULL CHECK (requested_brl_cents >= 1000),
  fee_brl_cents BIGINT NOT NULL DEFAULT 0 CHECK (fee_brl_cents >= 0),
  net_brl_cents BIGINT NOT NULL CHECK (net_brl_cents >= 0),
  pix_key_ciphertext BYTEA,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','processing','completed','failed','rejected','cancelled')),
  provider_reference TEXT,
  reviewed_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settled_at TIMESTAMPTZ
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  provider TEXT NOT NULL,
  provider_reference TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  amount_brl_cents BIGINT NOT NULL CHECK (amount_brl_cents > 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','failed','cancelled','refunded')),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX payments_provider_reference_uq ON payments(provider,provider_reference) WHERE provider_reference IS NOT NULL;

CREATE TABLE payment_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,
  event_id TEXT NOT NULL,
  signature_valid BOOLEAN NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received','processed','ignored','failed')),
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  UNIQUE (provider,event_id)
);

CREATE TABLE commission_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_code TEXT NOT NULL REFERENCES roles(code) ON DELETE RESTRICT,
  rate_bps INTEGER NOT NULL CHECK (rate_bps BETWEEN 0 AND 10000),
  basis TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (role_code,basis)
);

CREATE TABLE role_compensation (
  role_code TEXT PRIMARY KEY REFERENCES roles(code) ON DELETE RESTRICT,
  currency TEXT NOT NULL DEFAULT 'USD' CHECK (currency = 'USD'),
  monthly_min_cents BIGINT NOT NULL CHECK (monthly_min_cents >= 0),
  monthly_max_cents BIGINT NOT NULL CHECK (monthly_max_cents >= monthly_min_cents)
);

CREATE TABLE resellers (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  first_purchase_usd_cents BIGINT NOT NULL CHECK (first_purchase_usd_cents >= 50000),
  minimum_recharge_usd_cents BIGINT NOT NULL DEFAULT 5000 CHECK (minimum_recharge_usd_cents >= 5000),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending','active','suspended','closed')),
  approved_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE host_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  diamonds_received BIGINT NOT NULL DEFAULT 0 CHECK (diamonds_received >= 0),
  goal_target BIGINT NOT NULL DEFAULT 0 CHECK (goal_target >= 0),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),
  UNIQUE (host_user_id,period_start,period_end),
  CHECK (period_end > period_start)
);

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  scope TEXT NOT NULL CHECK (scope IN ('user','host','agency','family','room')),
  reward JSONB NOT NULL DEFAULT '{}'::jsonb,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE RESTRICT,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  progress BIGINT NOT NULL DEFAULT 0 CHECK (progress >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','claimed','expired')),
  completed_at TIMESTAMPTZ,
  ledger_transaction_id UUID REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  UNIQUE (task_id,user_id,period_start),
  CHECK (period_end > period_start)
);

CREATE TABLE ranking_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ranking_type TEXT NOT NULL,
  scope_type TEXT NOT NULL DEFAULT 'global',
  scope_id TEXT NOT NULL DEFAULT '',
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (ranking_type,scope_type,scope_id,period_start,period_end),
  CHECK (period_end > period_start)
);

CREATE TABLE ranking_entries (
  snapshot_id UUID NOT NULL REFERENCES ranking_snapshots(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rank_position INTEGER NOT NULL CHECK (rank_position > 0),
  score BIGINT NOT NULL CHECK (score >= 0),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (snapshot_id,user_id),
  UNIQUE (snapshot_id,rank_position)
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT REFERENCES rooms(id) ON DELETE SET NULL,
  sender_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  recipient_user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  paid_amount BIGINT NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  paid_currency TEXT CHECK (paid_currency IS NULL OR paid_currency = 'COIN_PURCHASED'),
  ledger_transaction_id UUID UNIQUE REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE coin_release_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  requested_amount BIGINT NOT NULL CHECK (requested_amount > 0),
  approved_amount BIGINT CHECK (approved_amount IS NULL OR approved_amount > 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','cancelled')),
  requested_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  reviewed_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE moderation_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_type TEXT NOT NULL CHECK (content_type IN ('name','image','bio','message','profile','room','other')),
  entity_id TEXT NOT NULL,
  reported_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  reviewed_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','review','removed','dismissed')),
  original_content TEXT,
  analysis JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  actor_user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE FUNCTION audit_log_forbid_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit logs are immutable';
END;
$$;

CREATE TRIGGER audit_logs_immutable BEFORE UPDATE OR DELETE ON audit_logs FOR EACH ROW EXECUTE FUNCTION audit_log_forbid_change();

CREATE TABLE account_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  device_hash TEXT,
  ip_address INET,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','revoked')),
  created_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  CHECK (user_id IS NOT NULL OR device_hash IS NOT NULL OR ip_address IS NOT NULL),
  CHECK (expires_at IS NULL OR expires_at > starts_at)
);

CREATE INDEX account_blocks_user_idx ON account_blocks(user_id) WHERE user_id IS NOT NULL;

CREATE INDEX account_blocks_device_idx ON account_blocks(device_hash) WHERE device_hash IS NOT NULL;

CREATE INDEX account_blocks_ip_idx ON account_blocks(ip_address) WHERE ip_address IS NOT NULL;

CREATE TABLE job_runs (
  job_name TEXT PRIMARY KEY,
  last_run_at TIMESTAMPTZ,
  data JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE economy_settings (
  setting_key TEXT PRIMARY KEY,
  setting_value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE legacy_import_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_name TEXT NOT NULL,
  source_table TEXT NOT NULL,
  source_record_id TEXT NOT NULL,
  raw_data JSONB NOT NULL,
  classification TEXT NOT NULL DEFAULT 'unclassified' CHECK (classification IN ('unclassified','test','real','mixed','reconciled')),
  imported_at TIMESTAMPTZ,
  UNIQUE (source_name,source_table,source_record_id)
);

INSERT INTO roles(code,label,hierarchy) VALUES
 ('participant','Participante',10),
 ('host','Host',20),
 ('room_owner','Dono de sala',30),
 ('moderator','Moderador',35),
 ('reseller','Revenda',40),
 ('agency_owner','Dono de agência',50),
 ('bd','BD',60),
 ('admin_official','ADM oficial',70),
 ('super_admin','Super ADM',80),
 ('admin_central','Admin central',90)
;

INSERT INTO commission_rules(role_code,rate_bps,basis) VALUES
 ('bd',100,'network_net_earnings'),
 ('admin_official',100,'network_net_earnings'),
 ('super_admin',200,'network_net_earnings')
;

INSERT INTO role_compensation(role_code,monthly_min_cents,monthly_max_cents) VALUES
 ('bd',10000,10000),
 ('admin_official',10000,10000),
 ('super_admin',30000,50000)
;

INSERT INTO economy_settings(setting_key,setting_value) VALUES
 ('minimum_withdrawal_brl_cents','1000'::jsonb),
 ('platform_brl_cents_per_usd','580'::jsonb),
 ('reseller_minimum_purchase_usd_cents','5000'::jsonb),
 ('reseller_first_purchase_minimum_usd_cents','50000'::jsonb),
 ('lucky_gift_platform_share_bps','7000'::jsonb),
 ('lucky_gift_minimum_age','18'::jsonb),
 ('host_cycle_close_days','[15,"month_end"]'::jsonb)
;

INSERT INTO ledger_accounts(currency,is_system,balance) VALUES
 ('COIN_PURCHASED',TRUE,0),
 ('COIN_GIFT',TRUE,0),
 ('DIAMOND',TRUE,0),
 ('BRL_CENTS',TRUE,0),
 ('USD_CENTS',TRUE,0)
;
