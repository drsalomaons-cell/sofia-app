const test = require('node:test');
const assert = require('node:assert/strict');
const { createWithdrawal, settleWithdrawalWebhook } = require('../services/withdrawal');

function fixtures(balance = 100) {
  let users = [{ id: 'u1', balance, reservedBalance: 0 }];
  let transactions = [];
  const store = {
    getUsers: () => users,
    saveUsers: (next) => { users = next; },
    getTransactions: () => transactions,
    saveTransactions: (next) => { transactions = next; },
    addTransaction: (tx) => { transactions.unshift(tx); return tx; },
  };
  return { store, get users() { return users; }, get transactions() { return transactions; } };
}
const economy = {
  processWithdraw: (amount) => ({ gross: amount, fee: 5, net: amount - 5, processingDays: 3, estimatedCompletion: new Date().toISOString() }),
  applyBalanceChange: (user, delta) => { const balance = Number(user.balance || 0) + delta; if (balance < 0) throw new Error('Saldo insuficiente'); return { ...user, balance }; },
};
const fraud = { analyzeTransaction: () => ({ blocked: false }) };

test('PagBank failure leaves user balance unchanged and releases reservation', async () => {
  const f = fixtures(100);
  let sawPendingBeforeProvider = false;
  const pagbank = { createPixWithdraw: async ({ pendingId }) => {
    sawPendingBeforeProvider = f.transactions.some((tx) => tx.id === pendingId && tx.status === 'pending') && f.users[0].reservedBalance === 25 && f.users[0].balance === 100;
    return { success: false, error: 'simulated PagBank failure', status: 'ERROR' };
  } };
  const result = await createWithdrawal({ userId: 'u1', amount: 25, pixKey: 'test@example.com', bankData: {}, requestId: 'test-failure-1', store: f.store, economy, fraud, pagbank });
  assert.equal(sawPendingBeforeProvider, true, 'transaction must be pending and amount reserved before provider call');
  assert.equal(result.statusCode, 502);
  assert.equal(f.users[0].balance, 100, 'real balance must not be debited on provider failure');
  assert.equal(f.users[0].reservedBalance, 0, 'reservation must be released on failure');
  assert.equal(f.transactions.length, 1);
  assert.equal(f.transactions[0].status, 'failed');
  assert.equal(f.transactions[0].reservedAmount, 0);
});

test('same idempotency key does not create a second withdrawal', async () => {
  const f = fixtures(100);
  let calls = 0;
  const pagbank = { createPixWithdraw: async () => { calls += 1; return { success: true, status: 'PENDING', transferId: 'provider-1' }; } };
  const args = { userId: 'u1', amount: 25, pixKey: 'test@example.com', bankData: {}, requestId: 'same-key', store: f.store, economy, fraud, pagbank };
  const first = await createWithdrawal(args);
  const second = await createWithdrawal(args);
  assert.equal(first.statusCode, 202);
  assert.equal(second.body.idempotentReplay, true);
  assert.equal(calls, 1);
  assert.equal(f.transactions.length, 1);
  assert.equal(f.users[0].balance, 100);
  assert.equal(f.users[0].reservedBalance, 25);
});

test('confirmed webhook debits once and releases reserved balance', () => {
  const f = fixtures(100);
  f.users[0].reservedBalance = 25;
  f.transactions.push({ id: 'withdraw-1', userId: 'u1', type: 'withdraw', amount: -25, reservedAmount: 25, status: 'pending', createdAt: new Date().toISOString() });
  const pending = { id: 'withdraw-1', type: 'withdraw' };
  const result = settleWithdrawalWebhook({ pending, event: { status: 'COMPLETED' }, store: f.store, economy });
  assert.equal(result.processed, true);
  assert.equal(f.users[0].balance, 75);
  assert.equal(f.users[0].reservedBalance, 0);
  assert.equal(f.transactions[0].status, 'completed');
  const duplicate = settleWithdrawalWebhook({ pending, event: { status: 'COMPLETED' }, store: f.store, economy });
  assert.equal(duplicate.duplicate, true);
  assert.equal(f.users[0].balance, 75);
});
