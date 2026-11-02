'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createNeonLedger } = require('../services/neon-ledger');

const validMoves = [
  { account_id: '11111111-1111-4111-8111-111111111111', amount: -25 },
  { account_id: '22222222-2222-4222-8222-222222222222', amount: 25 },
];

test('calls ledger_apply with parameterized values and returns transaction ID', async () => {
  let call;
  const pool = {
    query: async (...args) => {
      call = args;
      return { rows: [{ transaction_id: '33333333-3333-4333-8333-333333333333' }] };
    },
  };
  const ledger = createNeonLedger({ pool });
  const result = await ledger.applyLedger({
    idempotencyKey: 'test-order-1',
    kind: 'test_transfer',
    createdBy: 'user-1',
    meta: { source: 'unit-test' },
    moves: validMoves,
  });

  assert.equal(result, '33333333-3333-4333-8333-333333333333');
  assert.match(call[0], /SELECT ledger_apply/);
  assert.deepEqual(call[1], [
    'test-order-1',
    'test_transfer',
    'user-1',
    JSON.stringify({ source: 'unit-test' }),
    JSON.stringify(validMoves),
  ]);
});

test('rejects malformed financial payload before database access', async () => {
  let calls = 0;
  const ledger = createNeonLedger({ pool: { query: async () => { calls += 1; return { rows: [] }; } } });

  await assert.rejects(() => ledger.applyLedger({ idempotencyKey: '', kind: 'x', moves: validMoves }), /idempotencyKey/);
  await assert.rejects(() => ledger.applyLedger({ idempotencyKey: 'k', kind: '', moves: validMoves }), /kind/);
  await assert.rejects(() => ledger.applyLedger({ idempotencyKey: 'k', kind: 'x', moves: [{ account_id: 'a', amount: 1 }] }), /at least two/);
  await assert.rejects(() => ledger.applyLedger({ idempotencyKey: 'k', kind: 'x', moves: [{ account_id: 'a', amount: 1 }, { account_id: 'b', amount: 0 }] }), /non-zero safe integer/);
  await assert.rejects(() => ledger.applyLedger({ idempotencyKey: 'k', kind: 'x', moves: [{ account_id: 'a', amount: 1 }, { account_id: 'a', amount: -1 }] }), /duplicate account_id/);
  await assert.rejects(() => ledger.applyLedger({ idempotencyKey: 'k', kind: 'x', createdBy: 123, moves: validMoves }), /createdBy/);
  assert.equal(calls, 0);
});

test('propagates database errors without converting them into success', async () => {
  const ledger = createNeonLedger({
    pool: { query: async () => { throw new Error('database unavailable'); } },
  });
  await assert.rejects(
    () => ledger.applyLedger({ idempotencyKey: 'db-fail', kind: 'test', moves: validMoves }),
    /database unavailable/,
  );
});

test('requires a pool with query()', () => {
  assert.throws(() => createNeonLedger({ pool: null }), /pool with query/);
});
