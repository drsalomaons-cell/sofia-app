const FRAUD_THRESHOLDS = {
  REPETITIVE_GIFT_COUNT: 5,
  REPETITIVE_GIFT_WINDOW_MS: 60 * 60 * 1000,
  CIRCULAR_GIFT_WINDOW_MS: 24 * 60 * 60 * 1000,
  EVENTS_PER_DAY: 10,
  ACCOUNTS_PER_DEVICE: 5,
  ROOM_ACTIONS_PER_HOUR: 50,
};

const FRAUD_BLOCK_THRESHOLD = 80;

const SEVERITY_WEIGHT = { low: 10, medium: 25, high: 50, critical: 100 };

function detectSelfGift(senderId, recipientId) {
  if (senderId === recipientId) {
    return [{ type: 'self_gift', severity: 'critical', reason: 'Auto-presente bloqueado' }];
  }
  return [];
}

function detectRepetitiveGifts(recent = [], senderId, recipientId, now = Date.now()) {
  const count = recent.filter(
    (p) => p.from === senderId && p.to === recipientId && now - new Date(p.at).getTime() < FRAUD_THRESHOLDS.REPETITIVE_GIFT_WINDOW_MS
  ).length;
  if (count >= FRAUD_THRESHOLDS.REPETITIVE_GIFT_COUNT) {
    return [{ type: 'repetitive_gift', severity: 'medium', reason: 'Presentes repetitivos detectados', payload: { count } }];
  }
  return [];
}

function detectRoomAbuse(actionsLastHour = 0) {
  if (actionsLastHour > FRAUD_THRESHOLDS.ROOM_ACTIONS_PER_HOUR) {
    return [{ type: 'room_abuse', severity: 'medium', reason: 'Ações excessivas em sala' }];
  }
  return [];
}

function detectSuspiciousWithdraw(withdrawAmount, balance, recentWithdraws = 0) {
  const signals = [];
  if (withdrawAmount > balance) {
    signals.push({ type: 'overdraft', severity: 'critical', reason: 'Saque acima do saldo' });
  }
  if (recentWithdraws >= 3) {
    signals.push({ type: 'withdraw_spam', severity: 'high', reason: 'Múltiplos saques em curto período' });
  }
  return signals;
}

function computeRiskScore(signals = []) {
  return signals.reduce((sum, s) => sum + (SEVERITY_WEIGHT[s.severity] || 0), 0);
}

function shouldBlock(signals = []) {
  return computeRiskScore(signals) >= FRAUD_BLOCK_THRESHOLD;
}

function analyzeTransaction(ctx = {}) {
  const signals = [
    ...detectSelfGift(ctx.senderId, ctx.recipientId),
    ...detectRepetitiveGifts(ctx.recentGifts, ctx.senderId, ctx.recipientId),
    ...detectRoomAbuse(ctx.roomActionsLastHour),
    ...detectSuspiciousWithdraw(ctx.withdrawAmount, ctx.balance, ctx.recentWithdraws),
  ];
  return { signals, riskScore: computeRiskScore(signals), blocked: shouldBlock(signals) };
}

module.exports = {
  FRAUD_THRESHOLDS,
  FRAUD_BLOCK_THRESHOLD,
  detectSelfGift,
  detectRepetitiveGifts,
  detectRoomAbuse,
  detectSuspiciousWithdraw,
  computeRiskScore,
  shouldBlock,
  analyzeTransaction,
};
