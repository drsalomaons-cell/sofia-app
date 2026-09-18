/**
 * SOFIA Economy Engine — regras integradas (Siyacore + regra 50/50 SOFIA)
 */
const {
  DEFAULT_CONFIG,
  LEVEL_TABLE,
  VIP_TIERS,
  HOST_SALARY_TABLE,
  AGENCY_TIERS,
  OPENING_EVENT_RULES,
} = require('./config');

let runtimeConfig = { ...DEFAULT_CONFIG };

function setConfig(partial) {
  runtimeConfig = { ...runtimeConfig, ...partial };
  return runtimeConfig;
}

function getConfig() {
  return { ...runtimeConfig };
}

function getFullRules() {
  return {
    config: getConfig(),
    levelTable: LEVEL_TABLE,
    vipTiers: VIP_TIERS,
    hostSalaryTable: HOST_SALARY_TABLE,
    agencyTiers: AGENCY_TIERS,
    openingEvent: OPENING_EVENT_RULES,
    summary: {
      split: `${runtimeConfig.platformSplit * 100}% plataforma / ${runtimeConfig.userSplit * 100}% usuários`,
      roomGoalBonus: `${runtimeConfig.roomGoalBonusRate * 100}% meta de sala`,
      hostExtra: `${runtimeConfig.hostExtraBonusRate * 100}% extra Host`,
      withdrawFee: `até ${runtimeConfig.withdrawMaxFeeRate * 100}%`,
      withdrawDays: `${runtimeConfig.withdrawProcessingDays} dias úteis`,
      conversion: `1 diamante = ${runtimeConfig.diamondToCoinRate} moeda`,
    },
  };
}

function splitRoomRevenue(totalAmount) {
  const platform = round2(totalAmount * runtimeConfig.platformSplit);
  const distributed = round2(totalAmount * runtimeConfig.userSplit);
  return { platform, distributed, total: totalAmount };
}

function distributeAmongParticipants(distributedAmount, participantCount) {
  if (participantCount <= 0) return 0;
  return round2(distributedAmount / participantCount);
}

function calculateRoomGoalBonus(roomEarnings, goalMet) {
  if (!goalMet) return 0;
  return round2(roomEarnings * runtimeConfig.roomGoalBonusRate);
}

function calculateHostExtraBonus(roomEarnings, isHost) {
  if (!isHost) return 0;
  return round2(roomEarnings * runtimeConfig.hostExtraBonusRate);
}

function processRoomEarning(totalAmount, participantCount, options = {}) {
  const { isHost = false, roomGoalMet = false, vipTier = 'standard' } = options;
  const split = splitRoomRevenue(totalAmount);
  let perUser = distributeAmongParticipants(split.distributed, participantCount);

  const goalBonus = calculateRoomGoalBonus(totalAmount, roomGoalMet);
  const hostBonus = calculateHostExtraBonus(totalAmount, isHost);
  const vip = VIP_TIERS.find((v) => v.id === vipTier) || VIP_TIERS[0];
  const vipBonus = round2(perUser * (vip.bonusRate || 0));

  if (isHost) perUser = round2(perUser + hostBonus);
  if (roomGoalMet) perUser = round2(perUser + distributeAmongParticipants(goalBonus, participantCount));
  perUser = round2(perUser + vipBonus);

  return {
    ...split,
    perUser,
    participantCount,
    goalBonus,
    hostBonus,
    vipBonus,
    description: `50/50 + meta ${roomGoalMet ? '2%' : '0%'} + host ${isHost ? '1%' : '0%'}`,
  };
}

function calculateWithdrawFee(amount) {
  const fee = round2(amount * runtimeConfig.withdrawFeeRate);
  const maxFee = round2(amount * runtimeConfig.withdrawMaxFeeRate);
  return Math.min(fee, maxFee);
}

function processWithdraw(amount) {
  const fee = calculateWithdrawFee(amount);
  const net = round2(amount - fee);
  const processingDays = runtimeConfig.withdrawProcessingDays;
  return {
    gross: amount,
    fee,
    net,
    feeRate: runtimeConfig.withdrawFeeRate,
    processingDays,
    estimatedCompletion: addBusinessDays(new Date(), processingDays).toISOString(),
  };
}

function convertDiamondsToCoins(diamonds) {
  return round2(diamonds * runtimeConfig.diamondToCoinRate);
}

function convertCoinsToReal(coins) {
  return round2(coins * runtimeConfig.coinToRealRate);
}

function calculateLevel(xp = 0) {
  let level = 1;
  for (const row of LEVEL_TABLE) {
    if (xp >= row.xpRequired) level = row.level;
  }
  return level;
}

function getLevelInfo(level) {
  return LEVEL_TABLE.find((l) => l.level === level) || LEVEL_TABLE[0];
}

function getVipTier(totalSpend = 0) {
  let tier = VIP_TIERS[0];
  for (const v of VIP_TIERS) {
    if (totalSpend >= v.minSpend) tier = v;
  }
  return tier;
}

function getHostSalary(hostLevel = 0) {
  const row = HOST_SALARY_TABLE.find((h) => h.hostLevel === hostLevel)
    || HOST_SALARY_TABLE[HOST_SALARY_TABLE.length - 1];
  const configSalary = runtimeConfig.hostSalaryBase + hostLevel * runtimeConfig.hostSalaryPerLevel;
  return { ...row, salary: Math.max(row.baseSalary, configSalary) };
}

function calculateWeeklyAgencyBonus(agencyTier, poolAmount) {
  const tier = AGENCY_TIERS.find((a) => a.id === agencyTier) || AGENCY_TIERS[0];
  return round2(poolAmount * tier.weeklyBonusRate);
}

function processOpeningEvent(participantCount, isHost) {
  if (!OPENING_EVENT_RULES.enabled || participantCount < OPENING_EVENT_RULES.minParticipants) {
    return { bonus: 0, xp: 0, granted: false };
  }
  return {
    bonus: isHost ? OPENING_EVENT_RULES.hostBonus : OPENING_EVENT_RULES.participantBonus,
    xp: OPENING_EVENT_RULES.xpReward,
    granted: true,
  };
}

function calculateEarning(source, payload = {}) {
  switch (source) {
    case 'room_time':
      return round2((payload.minutes || 1) * runtimeConfig.roomTimeRatePerMinute);
    case 'message':
      return runtimeConfig.messageReward;
    case 'gift_received':
      return round2((payload.amount || 0) * runtimeConfig.userSplit);
    case 'referral':
      return runtimeConfig.referralBonus;
    case 'daily_login':
      return runtimeConfig.dailyLoginCoins;
    case 'opening_event':
      return payload.isHost ? OPENING_EVENT_RULES.hostBonus : OPENING_EVENT_RULES.participantBonus;
    default:
      return 0;
  }
}

function addXp(user, amount) {
  const xp = (user.xp || 0) + amount;
  const level = calculateLevel(xp);
  const info = getLevelInfo(level);
  return {
    ...user,
    xp,
    level,
    frame: info.frame,
    levelTitle: info.title,
  };
}

function applyBalanceChange(user, delta) {
  const balance = round2((user.balance || 0) + delta);
  if (balance < 0) throw new Error('Saldo insuficiente');
  return { ...user, balance };
}

function applyCoinsAndDiamonds(user, { coins = 0, diamonds = 0 }) {
  return {
    ...user,
    coins: round2((user.coins ?? user.balance ?? 0) + coins),
    balance: round2((user.balance || 0) + coins),
    diamonds: round2((user.diamonds || 0) + diamonds),
  };
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

function addBusinessDays(date, days) {
  const result = new Date(date);
  let added = 0;
  while (added < days) {
    result.setDate(result.getDate() + 1);
    const dow = result.getDay();
    if (dow !== 0 && dow !== 6) added++;
  }
  return result;
}

module.exports = {
  setConfig,
  getConfig,
  getFullRules,
  splitRoomRevenue,
  distributeAmongParticipants,
  calculateRoomGoalBonus,
  calculateHostExtraBonus,
  processRoomEarning,
  calculateWithdrawFee,
  processWithdraw,
  convertDiamondsToCoins,
  convertCoinsToReal,
  calculateLevel,
  getLevelInfo,
  getVipTier,
  getHostSalary,
  calculateWeeklyAgencyBonus,
  processOpeningEvent,
  calculateEarning,
  addXp,
  applyBalanceChange,
  applyCoinsAndDiamonds,
  LEVEL_TABLE,
  VIP_TIERS,
};
