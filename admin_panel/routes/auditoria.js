const { logs, salvarDados } = require('../data/store');

function registrarAcao(usuarioId, acao, ip) {
  logs.unshift({ id: 'log-' + Date.now(), usuarioId, acao, ip, data: new Date().toISOString() });
  if (logs.length > 1000) logs.pop();
  salvarDados();
}

module.exports = { registrarAcao };
