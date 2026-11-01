-- Tests for migration 002. Run only on Neon branch staging-migracao.
DO $$
DECLARE
  v_user_account UUID;
  v_system_account UUID;
  v_tx UUID;
  v_replay UUID;
  v_failed BOOLEAN;
  v_agency UUID;
BEGIN
  SELECT id INTO v_user_account
    FROM ledger_accounts
   WHERE owner_user_id='audit-idempotency-user' AND currency='COIN_PURCHASED';
  SELECT id INTO v_system_account
    FROM ledger_accounts
   WHERE is_system AND currency='COIN_PURCHASED';

  v_tx := ledger_apply(
    'audit-actor-text-id',
    'test_actor_text',
    'audit-idempotency-user',
    '{"test":true}'::jsonb,
    jsonb_build_array(
      jsonb_build_object('account_id',v_user_account,'amount',-1),
      jsonb_build_object('account_id',v_system_account,'amount',1)
    )
  );
  v_replay := ledger_apply(
    'audit-actor-text-id',
    'test_actor_text',
    'audit-idempotency-user',
    '{"test":true}'::jsonb,
    jsonb_build_array(
      jsonb_build_object('account_id',v_user_account,'amount',-1),
      jsonb_build_object('account_id',v_system_account,'amount',1)
    )
  );
  IF v_tx <> v_replay THEN RAISE EXCEPTION 'text actor idempotency failed'; END IF;

  INSERT INTO store_items(id,item_type,name) VALUES ('audit-game-item','game','Audit game');
  v_failed := FALSE;
  BEGIN
    INSERT INTO store_item_prices(item_id,currency,amount) VALUES ('audit-game-item','COIN_GIFT',10);
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'COIN_GIFT was allowed for a non-gift item'; END IF;

  INSERT INTO store_items(id,item_type,name) VALUES ('audit-ordinary-gift','gift','Audit ordinary gift');
  INSERT INTO gift_catalog(item_id,lucky_gift,platform_share_bps)
  VALUES ('audit-ordinary-gift',FALSE,NULL);
  INSERT INTO store_item_prices(item_id,currency,amount)
  VALUES ('audit-ordinary-gift','COIN_GIFT',10);

  v_failed := FALSE;
  BEGIN
    UPDATE gift_catalog
       SET lucky_gift=TRUE,platform_share_bps=7000
     WHERE item_id='audit-ordinary-gift';
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'lucky gift was allowed to retain COIN_GIFT pricing'; END IF;

  v_failed := FALSE;
  BEGIN
    INSERT INTO events(event_type,name,minimum_age)
    VALUES ('lucky_gift','Audit underage event',17);
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'lucky gift event accepted minimum age below 18'; END IF;

  INSERT INTO events(event_type,name,minimum_age)
  VALUES ('lucky_gift','Audit 18+ event',18);

  INSERT INTO resellers(user_id,first_purchase_usd_cents,status)
  VALUES ('audit-concurrency-20-user',50000,'active')
  ON CONFLICT (user_id) DO UPDATE SET status='active';

  INSERT INTO agencies(name) VALUES ('Audit synthetic agency') RETURNING id INTO v_agency;
  v_failed := FALSE;
  BEGIN
    INSERT INTO agency_memberships(agency_id,user_id,role_code)
    VALUES (v_agency,'audit-concurrency-20-user','agency_owner');
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'ordinary reseller was allowed into an agency'; END IF;

  v_failed := FALSE;
  BEGIN
    INSERT INTO host_cycles(host_user_id,period_start,period_end)
    VALUES ('audit-idempotency-user','2026-11-01','2026-11-14');
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'invalid fortnight cycle accepted'; END IF;

  INSERT INTO host_cycles(host_user_id,period_start,period_end)
  VALUES ('audit-idempotency-user','2026-11-01','2026-11-15');

  INSERT INTO store_items(id,item_type,name) VALUES ('audit-lucky-gift','gift','Audit lucky gift');
  INSERT INTO gift_catalog(item_id,lucky_gift,platform_share_bps)
  VALUES ('audit-lucky-gift',TRUE,7000);

  v_failed := FALSE;
  BEGIN
    UPDATE gift_catalog SET platform_share_bps=6000 WHERE item_id='audit-lucky-gift';
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'lucky gift accepted platform share other than 70 percent'; END IF;

  v_failed := FALSE;
  BEGIN
    INSERT INTO store_item_prices(item_id,currency,amount)
    VALUES ('audit-lucky-gift','COIN_GIFT',10);
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'lucky gift accepted COIN_GIFT'; END IF;

  v_failed := FALSE;
  BEGIN
    INSERT INTO store_item_prices(item_id,currency,amount)
    VALUES ('audit-ordinary-gift','DIAMOND',10);
  EXCEPTION WHEN OTHERS THEN v_failed := TRUE;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'DIAMOND was accepted as a store purchase currency'; END IF;

END;
$$;
