const { verify } = require('../auth/jwt');
function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ')) return res.status(401).json({ error: 'Token ausente' });
  try { req.user = verify(h.slice(7)); next(); }
  catch { return res.status(401).json({ error: 'Token invalido' }); }
}
function requireSelf(param) {
  return (req, res, next) => {
    const id = (req.params && req.params[param]) || (req.body && req.body[param]);
    if (id == null || String(id) !== String(req.user.id)) return res.status(403).json({ error: 'Acesso negado' });
    next();
  };
}
module.exports = { requireAuth, requireSelf };
