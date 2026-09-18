const cron = require('node-cron');
const store = require('../data/store');
const economy = require('../economy/engine');
const { AGENCY_TIERS } = require('../economy/config');

function txId() {
  return require('crypto').randomBytes(8).toString('hex');
}

function syncUserLevelsAndVip() {
  const users = store.getUsers();
  let changed = false;
  for (const u of users) {
    if (u.isAdmin || u.isRegionalAdmin) continue;
    const vip = economy.getVipTier(u.totalSpend || 0);
    const levelInfo = economy.getLevelInfo(u.level || 1);
    const next = {
      ...u,
      vipTier: vip.id,
      vipTag: vip.tag,
      frame: u.frame || levelInfo.frame,
      levelTitle: levelInfo.title,
    };
    if (JSON.stringify(next) !== JSON.stringify(u)) {
      Object.assign(u, next);
      changed = true;
    }
  }
  if (changed) store.saveUsers(users);
}

function processWeeklyAgencyBonuses() {
  const users = store.getUsers();
  const hosts = users.filter((u) => (u.hostLevel || 0) > 0 && !u.isAdmin);
  const pool = hosts.reduce((s, h) => s + (h.hostPoints || 0), 0) * (economy.getConfig().weeklyBonusPoolRate || 0.02);
  if (pool <= 0) return;

  const agencies = {};
  for (const h of hosts) {
    const agencyId = h.agencyId || 'starter';
    if (!agencies[agencyId]) agencies[agencyId] = [];
    agencies[agencyId].push(h);
  }

  for (const [agencyId, members] of Object.entries(agencies)) {
    const bonus = economy.calculateWeeklyAgencyBonus(agencyId, pool / Object.keys(agencies).length);
    const perHost = bonus / Math.max(members.length, 1);
    for (const h of members) {
      const idx = users.findIndex((u) => u.id === h.id);
      if (idx < 0) continue;
      users[idx] = economy.applyCoinsAndDiamonds(users[idx], { coins: perHost });
      store.addTransaction({
        id: txId(),
        userId: h.id,
        type: 'earning',
        amount: perHost,
        description: `Bônus semanal agência (${agencyId})`,
        status: 'completed',
        createdAt: new Date().toISOString(),
      });
    }
  }
  store.saveUsers(users);
}

function processPendingWithdrawals() {
  const txs = store.getTransactions();
  const now = Date.now();
  const pending = txs.filter((t) => t.type === 'withdraw' && t.status === 'pending');
  let changed = false;
  for (const tx of pending) {
    const created = new Date(tx.createdAt).getTime();
    const days = economy.getConfig().withdrawProcessingDays || 3;
    const businessMs = days * 24 * 60 * 60 * 1000 * 0.7;
    if (now - created >= businessMs) {
      tx.status = 'completed';
      tx.completedAt = new Date().toISOString();
      changed = true;
    }
  }
  if (changed) store.saveTransactions(txs);
}

function processOpeningEventRewards() {
  const rooms = store.getRooms().filter((r) => r.isActive);
  const users = store.getUsers();
  const rules = economy.processOpeningEvent;
  for (const room of rooms) {
    if (room.openingEventGranted) continue;
    const age = Date.now() - new Date(room.createdAt).getTime();
    const hours = age / 3600000;
    const participants = room.participants?.length || 0;
    if (hours > 72 || participants < 5) continue;

    const hostIdx = users.findIndex((u) => u.id === room.hostId);
    if (hostIdx >= 0) {
      const ev = rules(participants, true);
      if (ev.granted) {
        users[hostIdx] = economy.applyCoinsAndDiamonds(users[hostIdx], { coins: ev.bonus });
        users[hostIdx] = economy.addXp(users[hostIdx], ev.xp);
        store.addTransaction({
          id: txId(),
          userId: room.hostId,
          type: 'earning',
          amount: ev.bonus,
          description: `Evento abertura — Host: ${room.name}`,
          roomId: room.id,
          status: 'completed',
          createdAt: new Date().toISOString(),
        });
      }
    }
    room.openingEventGranted = true;
  }
  store.saveUsers(users);
  store.saveRooms(rooms);
}

function startScheduler() {
  cron.schedule('0 * * * *', () => {
    syncUserLevelsAndVip();
    processPendingWithdrawals();
  });

  cron.schedule('0 3 * * 1', () => {
    processWeeklyAgencyBonuses();
  });

  cron.schedule('*/30 * * * *', () => {
    processOpeningEventRewards();
  });

  syncUserLevelsAndVip();
  console.log('[CRON] Rotinas automáticas ativas (VIP sync, saques, bônus semanal, eventos)');
}

module.exports = { startScheduler, syncUserLevelsAndVip, processWeeklyAgencyBonuses, processPendingWithdrawals };
