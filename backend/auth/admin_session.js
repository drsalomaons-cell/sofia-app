const crypto = require('crypto');
const store = require('../data/store');
const roles = require('./roles');

const sessions = new Map();
const SESSION_TTL_MS = 8 * 60 * 60 * 1000;

function createSession(user) {
  const token = crypto.randomBytes(32).toString('hex');
  sessions.set(token, {
    userId: user.id,
    role: user.role,
    region: user.region,
    expiresAt: Date.now() + SESSION_TTL_MS,
  });
  return token;
}

function getSession(token) {
  if (!token) return null;
  const session = sessions.get(token);
  if (!session) return null;
  if (Date.now() > session.expiresAt) {
    sessions.delete(token);
    return null;
  }
  const user = store.findUser(session.userId);
  if (!user || !store.isAdminAccount(user)) return null;
  return { ...session, user };
}

function revokeSession(token) {
  sessions.delete(token);
}

function extractToken(req) {
  const auth = req.headers.authorization || '';
  if (auth.startsWith('Bearer ')) return auth.slice(7);
  return req.headers['x-admin-token'] || null;
}

function requireAdmin(req, res, next) {
  const token = extractToken(req);
  const session = getSession(token);
  if (!session) {
    return res.status(401).json({ error: 'Sessão admin inválida ou expirada' });
  }
  req.adminUser = session.user;
  req.adminSession = session;
  next();
}

function canAccessRegion(user, region) {
  if (roles.isCentralAdmin(user) || user.role === 'ADMIN_CENTRAL') return true;
  if (user.role === 'ADMIN_REGIONAL' || roles.isRegionalAdmin(user)) {
    return user.region === region;
  }
  return false;
}

module.exports = {
  createSession,
  getSession,
  revokeSession,
  extractToken,
  requireAdmin,
  canAccessRegion,
};
