const crypto = require('crypto');
const inFlight = new Map();

function makeError(statusCode, error, extra = {}) {
  return { statusCode, body: { error, ...extra } };
}

function providerStatus(payment) {
  return String(payment?.status || payment?.transfer?.status || payment?.data?.status || '').toUpperCase();
}

function isCompletedStatus(status) {
  return ['PAID', 'COMPLETED', 'CONFIRMED', 'SUCCESS', 'SUCCEEDED', 'PROCESSED', 'DONE'].includes(status);
}

function isFailedStatus(status) {
  return ['FAILED', 'REJECTED', 'CANCELLED', 'CANCELED', 'ERROR', 'DECLINED'].includes(status);
}

function saveTx(store, tx) {
  const transactions = store.getTransactions();
  const index = transactions.findIndex((item) => item.id === tx.id);
  if (index >= 0) transactions[index] = tx;
  else transactions.unshift(tx);
  store.saveTransactions(transactions);
  return tx;
}

function releaseReservation(user, amount) {
  user.reservedBalance = Math.max(0, Math.round(((Number(user.reservedBalance) || 0) - amount) * 100) / 100);
}

async function createWithdrawal({ userId, amount, pixKey, bankData, requestId, store, economy, fraud, pagbank }) {
  const key = String(requestId || '').trim();
  if (!key || key.length > 128) return makeError(400, 'requestId/Idempotency-Key obrigatório (1–128 caracteres)');
  if (!Number.isFinite(amount) || amount <= 0 || amount > 1000000) return makeError(400, 'Valor de saque inválido');
  if (!pixKey || typeof pixKey !== 'string' || pixKey.trim().length > 200) return makeError(400, 'Chave PIX inválida');

  const transactions = store.getTransactions();
  const prior = transactions.find((tx) => tx.type === 'withdraw' && tx.idempotencyKey === key);
  if (prior) {
    if (prior.userId !== userId || Number(prior.requestedAmount) !== Number(amount)) {
      return makeError(409, 'Idempotency-Key já utilizada para outra solicitação');
    }
    return { statusCode: prior.status === 'failed' ? 502 : 200, body: { transaction: prior, idempotentReplay: true, balance: (store.getUsers().find((u) => u.id === userId) || {}).balance } };
  }
  if (inFlight.has(key)) return inFlight.get(key);

  const operation = (async () => {
    const users = store.getUsers();
    const idx = users.findIndex((u) => u.id === userId);
    if (idx < 0) return makeError(404, 'Usuário não encontrado');

    const calc = economy.processWithdraw(amount);
    const totalDebit = calc.gross;
    const availableBalance = Math.round(((Number(users[idx].balance) || 0) - (Number(users[idx].reservedBalance) || 0)) * 100) / 100;
    if (availableBalance < totalDebit) return makeError(400, 'Saldo disponível insuficiente');

    const recentWithdraws = transactions.filter((tx) => tx.userId === userId && tx.type === 'withdraw' && Date.now() - new Date(tx.createdAt).getTime() < 86400000).length;
    const analysis = fraud.analyzeTransaction({ withdrawAmount: totalDebit, balance: availableBalance, recentWithdraws });
    if (analysis.blocked) return makeError(403, 'Saque bloqueado por segurança', { analysis });

    const now = new Date().toISOString();
    let tx = {
      id: crypto.randomBytes(16).toString('hex'), userId, type: 'withdraw', amount: -totalDebit,
      requestedAmount: amount, reservedAmount: totalDebit, idempotencyKey: key,
      description: `Saque PIX (taxa R$ ${calc.fee} - ${calc.processingDays} dias úteis)`,
      status: 'pending', pixKey, bankData, fee: calc.fee, netAmount: calc.net,
      estimatedCompletion: calc.estimatedCompletion, createdAt: now,
    };

    // Reserve first to prevent concurrent withdrawals spending the same available balance.
    users[idx].reservedBalance = Math.round(((Number(users[idx].reservedBalance) || 0) + totalDebit) * 100) / 100;
    store.saveUsers(users);
    saveTx(store, tx);

    let payment;
    try {
      payment = await pagbank.createPixWithdraw({ amount: calc.net, pixKey, userId, pendingId: tx.id });
    } catch (error) {
      payment = { success: false, error: error?.message || 'Falha ao chamar o provedor' };
    }

    const status = providerStatus(payment);
    const explicitlyFailed = payment?.success === false || isFailedStatus(status);
    if (explicitlyFailed) {
      const freshUsers = store.getUsers();
      const userIdx = freshUsers.findIndex((u) => u.id === userId);
      if (userIdx >= 0) {
        releaseReservation(freshUsers[userIdx], totalDebit);
        store.saveUsers(freshUsers);
      }
      tx = { ...tx, status: 'failed', reservedAmount: 0, failureReason: payment?.error || `Provedor recusou o saque (${status || 'sem status'})`, providerTransferId: payment?.transferId || payment?.id || null, completedAt: new Date().toISOString() };
      saveTx(store, tx);
      return { statusCode: 502, body: { error: 'Provedor de pagamento não confirmou o saque', transaction: tx, balance: (store.getUsers().find((u) => u.id === userId) || {}).balance, payment } };
    }

    const freshUsers = store.getUsers();
    const userIdx = freshUsers.findIndex((u) => u.id === userId);
    if (userIdx < 0) return makeError(500, 'Usuário desapareceu durante o processamento');
    if (isCompletedStatus(status)) {
      releaseReservation(freshUsers[userIdx], totalDebit);
      try {
        freshUsers[userIdx] = economy.applyBalanceChange(freshUsers[userIdx], -totalDebit);
      } catch (error) {
        return makeError(500, `Não foi possível concluir o débito: ${error.message}`);
      }
      store.saveUsers(freshUsers);
      tx = { ...tx, status: 'completed', reservedAmount: 0, providerTransferId: payment?.transferId || payment?.id || null, completedAt: new Date().toISOString() };
      saveTx(store, tx);
      return { statusCode: 200, body: { balance: freshUsers[userIdx].balance, transaction: tx, withdraw: calc, payment, pending: false } };
    }

    // Accepted / under analysis: keep the amount reserved, not debited, until webhook confirmation.
    tx = { ...tx, status: 'pending', providerTransferId: payment?.transferId || payment?.id || null, providerStatus: status || 'PENDING' };
    saveTx(store, tx);
    return { statusCode: 202, body: { balance: freshUsers[userIdx].balance, reservedBalance: freshUsers[userIdx].reservedBalance, transaction: tx, withdraw: calc, payment, pending: true } };
  })();

  inFlight.set(key, operation);
  try { return await operation; }
  finally { inFlight.delete(key); }
}

function settleWithdrawalWebhook({ pending, event, store, economy }) {
  if (!pending || pending.type !== 'withdraw') return { processed: false };
  const transactions = store.getTransactions();
  const txIndex = transactions.findIndex((tx) => tx.id === pending.id || tx.idempotencyKey === pending.id);
  if (txIndex < 0) return { processed: false };
  const tx = transactions[txIndex];
  if (tx.status === 'completed' || tx.status === 'failed') return { processed: true, duplicate: true };

  const status = String(event.status || '').toUpperCase();
  if (!isCompletedStatus(status) && !isFailedStatus(status)) return { processed: false };
  const users = store.getUsers();
  const idx = users.findIndex((user) => user.id === tx.userId);
  if (idx < 0) return { processed: false };
  const reserved = Number(tx.reservedAmount) || Math.abs(Number(tx.amount) || 0);
  releaseReservation(users[idx], reserved);
  const now = new Date().toISOString();
  let updated;
  if (isCompletedStatus(status)) {
    users[idx] = economy.applyBalanceChange(users[idx], -reserved);
    updated = { ...tx, status: 'completed', reservedAmount: 0, completedAt: now, providerStatus: status };
  } else {
    updated = { ...tx, status: 'failed', reservedAmount: 0, failureReason: `Provedor informou ${status}`, completedAt: now, providerStatus: status };
  }
  store.saveUsers(users);
  transactions[txIndex] = updated;
  store.saveTransactions(transactions);
  return { processed: true, transaction: updated };
}

module.exports = { createWithdrawal, settleWithdrawalWebhook, isCompletedStatus, isFailedStatus };
