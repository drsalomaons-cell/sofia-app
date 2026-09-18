/** Configuração econômica SOFIA — valores padrão (editáveis no admin) */
const DEFAULT_CONFIG = {
  platformSplit: 0.5,
  userSplit: 0.5,
  roomGoalBonusRate: 0.02,
  hostExtraBonusRate: 0.01,
  withdrawFeeRate: 0.05,
  withdrawMaxFeeRate: 0.05,
  withdrawProcessingDays: 3,
  diamondToCoinRate: 1.0,
  coinToRealRate: 1.0,
  xpPerLevel: 100,
  dailyLoginCoins: 50,
  dailyLoginXp: 10,
  referralBonus: 50,
  messageReward: 0.1,
  roomTimeRatePerMinute: 0.05,
  weeklyBonusPoolRate: 0.02,
  openingEventBonus: 100,
  openingEventXp: 25,
  roomGoalThreshold: 500,
  hostSalaryBase: 200,
  hostSalaryPerLevel: 50,
  pagbankSandbox: true,
};

const LEVEL_TABLE = [
  { level: 1, xpRequired: 0, coinsBonus: 0, title: 'Iniciante', frame: 'bronze' },
  { level: 2, xpRequired: 100, coinsBonus: 10, title: 'Explorador', frame: 'bronze' },
  { level: 3, xpRequired: 300, coinsBonus: 25, title: 'Social', frame: 'silver' },
  { level: 4, xpRequired: 600, coinsBonus: 50, title: 'Influencer', frame: 'silver' },
  { level: 5, xpRequired: 1000, coinsBonus: 100, title: 'Estrela', frame: 'gold' },
  { level: 6, xpRequired: 1500, coinsBonus: 150, title: 'Veterano', frame: 'gold' },
  { level: 7, xpRequired: 2200, coinsBonus: 200, title: 'Mestre', frame: 'platinum' },
  { level: 8, xpRequired: 3000, coinsBonus: 300, title: 'Lenda', frame: 'platinum' },
  { level: 9, xpRequired: 4000, coinsBonus: 400, title: 'Ícone', frame: 'diamond' },
  { level: 10, xpRequired: 5500, coinsBonus: 500, title: 'SOFIA Elite', frame: 'diamond' },
];

const VIP_TIERS = [
  { id: 'standard', name: 'Standard', minSpend: 0, bonusRate: 0, tag: null },
  { id: 'silver', name: 'VIP Prata', minSpend: 500, bonusRate: 0.05, tag: '🥈 VIP' },
  { id: 'gold', name: 'VIP Ouro', minSpend: 2000, bonusRate: 0.10, tag: '🥇 VIP' },
  { id: 'diamond', name: 'VIP Diamante', minSpend: 5000, bonusRate: 0.15, tag: '💎 VIP' },
];

const HOST_SALARY_TABLE = [
  { hostLevel: 0, baseSalary: 0, giftMultiplier: 1.0 },
  { hostLevel: 1, baseSalary: 200, giftMultiplier: 1.05 },
  { hostLevel: 2, baseSalary: 350, giftMultiplier: 1.10 },
  { hostLevel: 3, baseSalary: 500, giftMultiplier: 1.15 },
  { hostLevel: 4, baseSalary: 750, giftMultiplier: 1.20 },
  { hostLevel: 5, baseSalary: 1000, giftMultiplier: 1.25 },
];

const AGENCY_TIERS = [
  { id: 'starter', name: 'Agência Iniciante', minHosts: 1, weeklyBonusRate: 0.01 },
  { id: 'pro', name: 'Agência Pro', minHosts: 5, weeklyBonusRate: 0.02 },
  { id: 'elite', name: 'Agência Elite', minHosts: 15, weeklyBonusRate: 0.03 },
];

const OPENING_EVENT_RULES = {
  enabled: true,
  durationHours: 72,
  hostBonus: 100,
  participantBonus: 25,
  minParticipants: 5,
  xpReward: 25,
};

module.exports = {
  DEFAULT_CONFIG,
  LEVEL_TABLE,
  VIP_TIERS,
  HOST_SALARY_TABLE,
  AGENCY_TIERS,
  OPENING_EVENT_RULES,
};
