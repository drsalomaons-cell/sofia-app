'use strict';

/**
 * Minimal adapter for the consolidated SOFIA ledger schema (migrations 001/002).
 *
 * This adapter is intentionally not wired into the legacy store. The legacy
 * postgres.js expects JSONB "data" columns and auto-runs schema.sql, while the
 * consolidated schema is normalized and has different columns. Wiring the
 * two together before a repository-wide data-access migration would break
 * existing reads/writes.
 *
 * Pass an existing node-postgres Pool. Never pass a client-controlled amount
 * without resolving it against server-side business rules first.
 */
function createNeonLedger({ pool }) {
  if (!pool || typeof pool.query !== 'function') {
    throw new TypeError('A node-postgres pool with query() is required');
  }

  async function applyLedger({
    idempotencyKey,
    kind,
    createdBy = null,
    meta = {},
    moves,
  }) {
    if (typeof idempotencyKey !== 'string'
      || idempotencyKey.trim().length < 1
      || idempotencyKey.length > 128) {
      throw new TypeError('idempotencyKey must contain 1 to 128 characters');
    }
    if (typeof kind !== 'string' || !kind.trim()) {
      throw new TypeError('kind is required');
    }
    if (createdBy !== null && typeof createdBy !== 'string') {
      throw new TypeError('createdBy must be a text user ID or null');
    }
    if (!meta || typeof meta !== 'object' || Array.isArray(meta)) {
      throw new TypeError('meta must be a JSON object');
    }
    if (!Array.isArray(moves) || moves.length < 2) {
      throw new TypeError('moves must contain at least two ledger entries');
    }

    const seen = new Set();
    for (const move of moves) {
      if (!move || typeof move.account_id !== 'string' || !move.account_id.trim()) {
        throw new TypeError('each move requires an account_id');
      }
      if (!Number.isSafeInteger(move.amount) || move.amount === 0) {
        throw new TypeError('each move amount must be a non-zero safe integer');
      }
      if (seen.has(move.account_id)) {
        throw new TypeError('duplicate account_id in moves');
      }
      seen.add(move.account_id);
    }

    const result = await pool.query(
      'SELECT ledger_apply($1::text, $2::text, $3::text, $4::jsonb, $5::jsonb) AS transaction_id',
      [
        idempotencyKey,
        kind,
        createdBy,
        JSON.stringify(meta),
        JSON.stringify(moves),
      ],
    );

    const transactionId = result?.rows?.[0]?.transaction_id;
    if (!transactionId) {
      throw new Error('ledger_apply did not return a transaction ID');
    }
    return transactionId;
  }

  return { applyLedger };
}

module.exports = { createNeonLedger };
