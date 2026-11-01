-- Testes do núcleo financeiro. Executar exclusivamente em staging-migracao.
-- A preparação cria dois usuários sintéticos e contas com saldos de teste.
DO $$
DECLARE
  v_wallet UUID;
  v_user_account UUID;
  v_system_account UUID;
  v_tx UUID;
  v_replay UUID;
  v_balance BIGINT;
  v_failed BOOLEAN;
  v_i INTEGER;
BEGIN
  INSERT INTO users(id,status) VALUES ('audit-idempotency-user','active')
  ON CONFLICT (id) DO NOTHING;
  INSERT INTO users(id,status) VALUES ('audit-concurrency-user','active')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO wallets(user_id) VALUES ('audit-idempotency-user')
  ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO wallets(user_id) VALUES ('audit-concurrency-user')
  ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet FROM wallets WHERE user_id='audit-idempotency-user';
  INSERT INTO ledger_accounts(wallet_id,owner_user_id,currency,is_system,balance)
  VALUES (v_wallet,'audit-idempotency-user','COIN_PURCHASED',FALSE,1000)
  ON CONFLICT DO NOTHING;

  SELECT id INTO v_wallet FROM wallets WHERE user_id='audit-concurrency-user';
  INSERT INTO ledger_accounts(wallet_id,owner_user_id,currency,is_system,balance)
  VALUES (v_wallet,'audit-concurrency-user','COIN_PURCHASED',FALSE,100)
  ON CONFLICT DO NOTHING;

  SELECT id INTO v_user_account FROM ledger_accounts WHERE owner_user_id='audit-idempotency-user' AND currency='COIN_PURCHASED';
  SELECT id INTO v_system_account FROM ledger_accounts WHERE is_system AND currency='COIN_PURCHASED';

  v_tx := ledger_apply(
    'audit-idempotency-sequential',
    'test_idempotency',
    NULL,
    '{}'::jsonb,
    jsonb_build_array(
      jsonb_build_object('account_id',v_user_account,'amount',-10),
      jsonb_build_object('account_id',v_system_account,'amount',10)
    )
  );
  FOR v_i IN 1..20 LOOP
    v_replay := ledger_apply(
      'audit-idempotency-sequential',
      'test_idempotency',
      NULL,
      '{}'::jsonb,
      jsonb_build_array(
        jsonb_build_object('account_id',v_user_account,'amount',-10),
        jsonb_build_object('account_id',v_system_account,'amount',10)
      )
    );
    IF v_replay <> v_tx THEN RAISE EXCEPTION 'idempotency replay returned a different transaction'; END IF;
  END LOOP;

  SELECT balance INTO v_balance FROM ledger_accounts WHERE id=v_user_account;
  IF v_balance <> 990 THEN RAISE EXCEPTION 'idempotency test failed: expected 990, got %',v_balance; END IF;

  v_failed := FALSE;
  BEGIN
    PERFORM ledger_apply(
      'audit-negative-balance',
      'test_overdraw',
      NULL,
      '{}'::jsonb,
      jsonb_build_array(
        jsonb_build_object('account_id',v_user_account,'amount',-2000),
        jsonb_build_object('account_id',v_system_account,'amount',2000)
      )
    );
  EXCEPTION WHEN OTHERS THEN
    v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'negative balance was not rejected'; END IF;

  SELECT balance INTO v_balance FROM ledger_accounts WHERE id=v_user_account;
  IF v_balance < 0 OR v_balance <> 990 THEN RAISE EXCEPTION 'negative balance test changed balance'; END IF;

  IF EXISTS (
    SELECT a.currency
    FROM ledger_entries e JOIN ledger_accounts a ON a.id=e.account_id
    GROUP BY a.currency
    HAVING sum(e.amount) <> 0
  ) THEN RAISE EXCEPTION 'ledger entries are not balanced by currency'; END IF;

  v_failed := FALSE;
  BEGIN
    UPDATE ledger_entries SET amount=amount WHERE transaction_id=v_tx;
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'ledger_entries UPDATE was not blocked'; END IF;

  v_failed := FALSE;
  BEGIN
    DELETE FROM ledger_entries WHERE transaction_id=v_tx;
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'ledger_entries DELETE was not blocked'; END IF;

  v_failed := FALSE;
  BEGIN
    UPDATE ledger_transactions SET meta=meta WHERE id=v_tx;
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'ledger_transactions UPDATE was not blocked'; END IF;

  v_failed := FALSE;
  BEGIN
    DELETE FROM ledger_transactions WHERE id=v_tx;
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'ledger_transactions DELETE was not blocked'; END IF;
END;
$$;

-- Concurrent test is orchestrated separately: run 50 simultaneous ledger_apply calls
-- against audit-concurrency-user (balance 100), each moving -10 from that account
-- and +10 to the COIN_PURCHASED system account. Expected: 10 commits, 40 rejected.
-- Idempotency concurrency test: 20 simultaneous identical calls using one key;
-- expected: one transaction UUID, one debit, exactly two ledger entries.
SELECT
  (SELECT id FROM ledger_accounts WHERE owner_user_id='audit-concurrency-user' AND currency='COIN_PURCHASED') AS concurrency_account_id,
  (SELECT id FROM ledger_accounts WHERE is_system AND currency='COIN_PURCHASED') AS system_account_id,
  (SELECT id FROM ledger_accounts WHERE owner_user_id='audit-idempotency-user' AND currency='COIN_PURCHASED') AS idempotency_account_id;
