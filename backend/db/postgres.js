const fs = require('fs');
const path = require('path');

let pool = null;
let ready = false;

async function initPool() {
  const url = process.env.DATABASE_URL || process.env.SUPABASE_DB_URL;
  if (!url) return false;
  const { Pool } = require('pg');
  pool = new Pool({
    connectionString: url,
    ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false },
  });
  const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(schema);
  ready = true;
  console.log('[DB] PostgreSQL conectado');
  return true;
}

function isPgActive() {
  return ready && pool;
}

async function pgReadCollection(table) {
  const res = await pool.query(`SELECT data FROM ${table} ORDER BY 1`);
  return res.rows.map((r) => r.data);
}

async function pgWriteCollection(table, items, idField = 'id') {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`DELETE FROM ${table}`);
    for (const item of items) {
      const id = item[idField];
      if (table === 'users') {
        await client.query(
          'INSERT INTO users (id, data, email, updated_at) VALUES ($1, $2, $3, NOW()) ON CONFLICT (id) DO UPDATE SET data = $2, email = $3, updated_at = NOW()',
          [id, item, item.email || null]
        );
      } else if (table === 'rooms') {
        await client.query(
          'INSERT INTO rooms (id, data, is_active, region, updated_at) VALUES ($1, $2, $3, $4, NOW()) ON CONFLICT (id) DO UPDATE SET data = $2, is_active = $3, region = $4, updated_at = NOW()',
          [id, item, item.isActive !== false, item.region || null]
        );
      } else if (table === 'transactions') {
        await client.query(
          'INSERT INTO transactions (id, user_id, type, data, created_at) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id) DO UPDATE SET data = $4',
          [id, item.userId || null, item.type || null, item, item.createdAt || new Date().toISOString()]
        );
      } else if (table === 'gift_catalog') {
        await client.query(
          'INSERT INTO gift_catalog (id, data) VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET data = $2',
          [id, item]
        );
      } else if (table === 'gift_log') {
        await client.query('INSERT INTO gift_log (data, created_at) VALUES ($1, NOW())', [item]);
      }
    }
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function pgGetUsers() {
  return pgReadCollection('users');
}

async function pgSaveUsers(users) {
  await pgWriteCollection('users', users);
}

async function pgGetRooms() {
  return pgReadCollection('rooms');
}

async function pgSaveRooms(rooms) {
  await pgWriteCollection('rooms', rooms);
}

async function pgGetTransactions() {
  const res = await pool.query('SELECT data FROM transactions ORDER BY created_at DESC');
  return res.rows.map((r) => r.data);
}

async function pgSaveTransactions(txs) {
  await pgWriteCollection('transactions', txs);
}

async function pgAddTransaction(tx) {
  await pool.query(
    'INSERT INTO transactions (id, user_id, type, data, created_at) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id) DO NOTHING',
    [tx.id, tx.userId, tx.type, tx, tx.createdAt || new Date().toISOString()]
  );
}

async function pgGetGiftCatalog() {
  return pgReadCollection('gift_catalog');
}

async function pgGetGiftLog() {
  const res = await pool.query('SELECT data FROM gift_log ORDER BY created_at DESC LIMIT 500');
  return res.rows.map((r) => r.data);
}

async function pgAddGiftLog(entry) {
  await pool.query('INSERT INTO gift_log (data, created_at) VALUES ($1, NOW())', [{ ...entry, at: new Date().toISOString() }]);
}

async function pgGetEconomyConfig() {
  const res = await pool.query('SELECT data FROM economy_config WHERE id = 1');
  return res.rows[0]?.data || null;
}

async function pgSaveEconomyConfig(cfg) {
  await pool.query(
    'INSERT INTO economy_config (id, data, updated_at) VALUES (1, $1, NOW()) ON CONFLICT (id) DO UPDATE SET data = $1, updated_at = NOW()',
    [cfg]
  );
}

async function pgAddPendingPayment(p) {
  await pool.query(
    'INSERT INTO pending_payments (id, user_id, amount, type, status, external_id, data) VALUES ($1,$2,$3,$4,$5,$6,$7)',
    [p.id, p.userId, p.amount, p.type, p.status || 'pending', p.externalId || null, p]
  );
}

async function pgFindPendingPayment(id) {
  const res = await pool.query('SELECT * FROM pending_payments WHERE id = $1 OR external_id = $1', [id]);
  return res.rows[0] || null;
}

async function pgCompletePendingPayment(id, status) {
  await pool.query(
    'UPDATE pending_payments SET status = $1, completed_at = NOW() WHERE id = $2 OR external_id = $2',
    [status, id]
  );
}

async function pgGetPendingPayments(status = 'pending') {
  const res = await pool.query('SELECT * FROM pending_payments WHERE status = $1', [status]);
  return res.rows;
}

async function pgJobLastRun(jobName) {
  const res = await pool.query('SELECT last_run_at, data FROM job_runs WHERE job_name = $1', [jobName]);
  return res.rows[0] || null;
}

async function pgJobMarkRun(jobName, data = {}) {
  await pool.query(
    'INSERT INTO job_runs (job_name, last_run_at, data) VALUES ($1, NOW(), $2) ON CONFLICT (job_name) DO UPDATE SET last_run_at = NOW(), data = $2',
    [jobName, data]
  );
}

module.exports = {
  initPool,
  isPgActive,
  pgGetUsers,
  pgSaveUsers,
  pgGetRooms,
  pgSaveRooms,
  pgGetTransactions,
  pgSaveTransactions,
  pgAddTransaction,
  pgGetGiftCatalog,
  pgGetGiftLog,
  pgAddGiftLog,
  pgGetEconomyConfig,
  pgSaveEconomyConfig,
  pgAddPendingPayment,
  pgFindPendingPayment,
  pgCompletePendingPayment,
  pgGetPendingPayments,
  pgJobLastRun,
  pgJobMarkRun,
};
