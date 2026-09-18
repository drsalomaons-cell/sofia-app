const { dispositivos, salvarDados } = require('../data/store');

function registrarDispositivo(usuarioId, dados) {
  const existente = dispositivos.find(d => d.usuarioId === usuarioId && d.imei === dados.imei);
  if (existente) {
    existente.ultimoAcesso = new Date().toISOString();
    existente.ultimoIp = dados.ip;
  } else {
    dispositivos.push({
      id: 'dev-' + Date.now(),
      usuarioId,
      imei: dados.imei || 'indefinido',
      ultimoAcesso: new Date().toISOString(),
      ultimoIp: dados.ip
    });
  }
  salvarDados();
}

module.exports = { registrarDispositivo };
