const jwt = require('jsonwebtoken');
const S = process.env.JWT_SECRET;
if (!S || S.length < 32) { console.error('[FATAL] JWT_SECRET ausente/curto'); process.exit(1); }
module.exports = {
  sign: (u) => jwt.sign({ id: u.id, role: u.role || 'participant' }, S, { expiresIn: '7d' }),
  verify: (t) => jwt.verify(t, S)
};
