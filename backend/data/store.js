const fs = require('fs');
const path = require('path');
const pg = require('../db/postgres');

const DATA_DIR = path.join(__dirname, 'data');
const DEFAULT_ADMIN_PASSWORD = process.env.ADMIN_CENTRAL_PASSWORD || 'Sofia@2026';

let pgCache = { users: null, rooms: null, transactions: null, gift_catalog: null, gift_log: null };

const REGIONAL_ADMINS = [
  { id: 'admin-regional-sul', email: 'regional.sul@sofia.app', region: 'América do Sul', name: 'Admin Regional — América do Sul' },
  { id: 'admin-regional-norte', email: 'regional.norte@sofia.app', region: 'América do Norte', name: 'Admin Regional — América do Norte' },
  { id: 'admin-regional-asia', email: 'regional.asia@sofia.app', region: 'Ásia', name: 'Admin Regional — Ásia' },
  { id: 'admin-regional-africa', email: 'regional.africa@sofia.app', region: 'África', name: 'Admin Regional — África' },
];

function usePg() {
  return pg.isPgActive();
}

function ensureDir() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
}

function filePath(name) {
  return path.join(DATA_DIR, `${name}.json`);
}

function read(name, fallback) {
  ensureDir();
  const fp = filePath(name);
  if (!fs.existsSync(fp)) {
    write(name, fallback);
    return JSON.parse(JSON.stringify(fallback));
  }
  return JSON.parse(fs.readFileSync(fp, 'utf8'));
}

function write(name, data) {
  ensureDir();
  fs.writeFileSync(filePath(name), JSON.stringify(data, null, 2));
}

function buildSeats(count, hostId, hostName) {
  return Array.from({ length: count }, (_, i) => ({
    index: i,
    userId: i === 0 ? hostId : null,
    userName: i === 0 ? hostName : null,
    role: i === 0 ? 'owner' : 'participant',
    isMuted: false,
    isLocked: false,
    giftCount: 0,
  }));
}

function ensureDefaultAdmins() {
  let users = getUsers();
  const centralEmail = process.env.ADMIN_CENTRAL_EMAIL || 'admin@sofia.app';
  const centralHash = require('../auth/password').hashPassword(DEFAULT_ADMIN_PASSWORD);

  const centralIdx = users.findIndex((u) => u.email === centralEmail);
  const centralUser = {
    id: 'admin-central',
    name: 'Admin Central SOFIA',
    email: centralEmail,
    passwordHash: centralHash,
    phone: '(11) 90000-0001',
    gender: 'Outro',
    interestedIn: 'Todos',
    region: 'Global',
    balance: 0,
    coins: 0,
    diamonds: 0,
    level: 99,
    points: 99999,
    xp: 9900,
    referrals: 0,
    isAdmin: true,
    isRegionalAdmin: false,
    role: 'ADMIN_CENTRAL',
    adminLevel: 'ADMIN_CENTRAL',
    createdAt: centralIdx >= 0 ? users[centralIdx].createdAt : new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  if (centralIdx >= 0) users[centralIdx] = { ...users[centralIdx], ...centralUser };
  else users.unshift(centralUser);

  for (const reg of REGIONAL_ADMINS) {
    const idx = users.findIndex((u) => u.email === reg.email);
    const regionalUser = {
      id: reg.id,
      name: reg.name,
      email: reg.email,
      passwordHash: require('../auth/password').hashPassword(DEFAULT_ADMIN_PASSWORD),
      phone: '(11) 90000-0099',
      gender: 'Outro',
      interestedIn: 'Todos',
      region: reg.region,
      balance: 0,
      level: 50,
      points: 5000,
      xp: 500,
      referrals: 0,
      isAdmin: false,
      isRegionalAdmin: true,
      role: 'ADMIN_REGIONAL',
      adminLevel: 'ADMIN_REGIONAL',
      createdAt: idx >= 0 ? users[idx].createdAt : new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    if (idx >= 0) users[idx] = { ...users[idx], ...regionalUser };
    else users.push(regionalUser);
  }

  users = users.map((u) => {
    if (u.password && !u.passwordHash) {
      u.passwordHash = require('../auth/password').hashPassword(u.password);
      delete u.password;
    }
    return u;
  });

  const demoIdx = users.findIndex((u) => u.email === 'demo@sofia.app');
  if (demoIdx < 0) {
    users.push({
      id: 'user-demo',
      name: 'Usuário Demo',
      email: 'demo@sofia.app',
      passwordHash: require('../auth/password').hashPassword(DEFAULT_ADMIN_PASSWORD),
      phone: '(11) 99999-0000',
      gender: 'Outro',
      interestedIn: 'Todos',
      region: 'América do Sul',
      balance: 1250,
      coins: 1250,
      diamonds: 120,
      level: 5,
      levelTitle: 'Estrela',
      frame: 'gold',
      vipTier: 'silver',
      totalSpend: 650,
      hostLevel: 1,
      hostPoints: 200,
      points: 850,
      xp: 450,
      referrals: 2,
      isAdmin: false,
      isRegionalAdmin: false,
      role: 'participant',
      createdAt: new Date().toISOString(),
    });
  } else {
    const d = users[demoIdx];
    users[demoIdx] = {
      ...d,
      coins: d.coins ?? d.balance ?? 1250,
      diamonds: d.diamonds ?? 120,
      levelTitle: d.levelTitle || 'Estrela',
      frame: d.frame || 'gold',
      vipTier: d.vipTier || 'silver',
      totalSpend: d.totalSpend ?? 650,
      hostLevel: d.hostLevel ?? 1,
    };
  }

  saveUsers(users);
  return users;
}

function initSeeds() {
  ensureDefaultAdmins();
  const rooms = getRooms();
  if (rooms.length === 0) {
    saveRooms([
      {
        id: 'room-1',
        name: 'Festa na Praia',
        description: 'Venha curtir uma festa incrível!',
        theme: 'Festa',
        coverUrl: '',
        chairs: 12,
        currentUsers: 3,
        isPrivate: false,
        allowGuests: true,
        hostId: 'user-demo',
        hostName: 'Usuário Demo',
        moderatorIds: [],
        participants: ['user-demo', '1', '2'],
        bannedUsers: [],
        region: 'América do Sul',
        earnings: 150,
        isActive: true,
        seats: buildSeats(12, 'user-demo', 'Usuário Demo'),
        createdAt: new Date(Date.now() - 7200000).toISOString(),
      },
      {
        id: 'room-2',
        name: 'Conversa Tech',
        description: 'Discussões sobre tecnologia',
        theme: 'Conversa',
        coverUrl: '',
        chairs: 8,
        currentUsers: 2,
        isPrivate: false,
        allowGuests: true,
        hostId: '1',
        hostName: 'Maria',
        moderatorIds: [],
        participants: ['1', '2'],
        bannedUsers: [],
        region: 'América do Sul',
        earnings: 80,
        isActive: true,
        seats: buildSeats(8, '1', 'Maria'),
        createdAt: new Date(Date.now() - 3600000).toISOString(),
      },
    ]);
  }
  read('transactions', []);
  getGiftLog();
  if (getGiftCatalog().length === 0) {
    const catalog = [
      { id: 'rose', name: 'Rosa', price: 10, tier: 'common', emoji: '🌹' },
      { id: 'star', name: 'Estrela', price: 50, tier: 'rare', emoji: '⭐' },
      { id: 'crown', name: 'Coroa', price: 200, tier: 'epic', emoji: '👑' },
      { id: 'diamond', name: 'Diamante', price: 500, tier: 'legendary', emoji: '💎' },
    ];
    if (usePg()) pgCache.gift_catalog = catalog;
    else write('gift_catalog', catalog);
  }
}

function getUsers() {
  if (usePg()) return pgCache.users || [];
  return read('users', []);
}

function saveUsers(users) {
  if (usePg()) {
    pgCache.users = users;
    pg.pgSaveUsers(users).catch((e) => console.error('[DB] saveUsers', e.message));
    return;
  }
  write('users', users);
}

function findUser(id) {
  return getUsers().find((u) => u.id === id) || null;
}

function findUserByEmail(email) {
  return getUsers().find((u) => u.email === email) || null;
}

function verifyUserPassword(user, plain) {
  if (!user) return false;
  const { verifyPassword } = require('../auth/password');
  const hash = user.passwordHash || user.password;
  return verifyPassword(plain, hash);
}

function isAdminAccount(user) {
  if (!user) return false;
  return user.role === 'ADMIN_CENTRAL' || user.role === 'ADMIN_REGIONAL'
    || user.adminLevel === 'ADMIN_CENTRAL' || user.adminLevel === 'ADMIN_REGIONAL'
    || user.isAdmin || user.isRegionalAdmin;
}

function getRooms() {
  if (usePg()) return pgCache.rooms || [];
  return read('rooms', []);
}

function saveRooms(rooms) {
  if (usePg()) {
    pgCache.rooms = rooms;
    pg.pgSaveRooms(rooms).catch((e) => console.error('[DB] saveRooms', e.message));
    return;
  }
  write('rooms', rooms);
}

function findRoom(id) {
  return getRooms().find((r) => r.id === id) || null;
}

function getTransactions() {
  if (usePg()) return pgCache.transactions || [];
  return read('transactions', []);
}

function saveTransactions(txs) {
  if (usePg()) {
    pgCache.transactions = txs;
    pg.pgSaveTransactions(txs).catch((e) => console.error('[DB] saveTransactions', e.message));
    return;
  }
  write('transactions', txs);
}

function addTransaction(tx) {
  if (usePg()) {
    pg.pgAddTransaction(tx).catch((e) => console.error('[DB] addTransaction', e.message));
    pgCache.transactions = [tx, ...(pgCache.transactions || [])];
    return tx;
  }
  const txs = getTransactions();
  txs.unshift(tx);
  saveTransactions(txs);
  return tx;
}

function getGiftCatalog() {
  if (usePg()) {
    const items = pgCache.gift_catalog;
    if (items && items.length) return items;
  }
  return read('gift_catalog', []);
}

function getGiftLog() {
  if (usePg()) return pgCache.gift_log || [];
  return read('gift_log', []);
}

function addGiftLog(entry) {
  const row = { ...entry, at: new Date().toISOString() };
  if (usePg()) {
    pg.pgAddGiftLog(row).catch((e) => console.error('[DB] addGiftLog', e.message));
    pgCache.gift_log = [row, ...(pgCache.gift_log || [])].slice(0, 500);
    return;
  }
  const log = getGiftLog();
  log.unshift({ ...entry, at: new Date().toISOString() });
  write('gift_log', log.slice(0, 500));
}

function publicUser(u) {
  if (!u) return null;
  const { password, passwordHash, ...safe } = u;
  return safe;
}

function publicAppUser(u) {
  const safe = publicUser(u);
  if (!safe) return null;
  return {
    ...safe,
    isAdmin: false,
    isRegionalAdmin: false,
    role: 'participant',
    adminLevel: null,
  };
}

async function initStore() {
  const ok = await pg.initPool();
  if (ok) {
    pgCache.users = await pg.pgGetUsers();
    pgCache.rooms = await pg.pgGetRooms();
    pgCache.transactions = await pg.pgGetTransactions();
    pgCache.gift_catalog = await pg.pgGetGiftCatalog();
    pgCache.gift_log = await pg.pgGetGiftLog();
    if (!pgCache.users.length) {
      initSeedsJsonOnly();
      await pg.pgSaveUsers(pgCache.users);
      await pg.pgSaveRooms(pgCache.rooms);
    }
    console.log('[Store] PostgreSQL/Supabase ativo');
  } else {
    console.log('[Store] JSON local (defina DATABASE_URL para PostgreSQL)');
    initSeeds();
    return;
  }
  initSeeds();
}

function initSeedsJsonOnly() {
  pgCache.users = read('users', []);
  pgCache.rooms = read('rooms', []);
  pgCache.transactions = read('transactions', []);
  pgCache.gift_catalog = read('gift_catalog', []);
  pgCache.gift_log = read('gift_log', []);
}

module.exports = {
  read,
  write,
  getUsers,
  saveUsers,
  findUser,
  findUserByEmail,
  verifyUserPassword,
  isAdminAccount,
  ensureDefaultAdmins,
  getRooms,
  saveRooms,
  findRoom,
  getTransactions,
  saveTransactions,
  addTransaction,
  getGiftCatalog,
  getGiftLog,
  addGiftLog,
  publicUser,
  publicAppUser,
  buildSeats,
  initStore,
  usePg,
};
