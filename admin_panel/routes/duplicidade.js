const { usuarios } = require('../data/store');

function verificarDuplicidade(dados) {
  const alertas = [];
  const porEmail = usuarios.filter(u => u.email === dados.email && u.ativo);
  if (porEmail.length > 1) alertas.push({ tipo: 'email', mensagem: `E-mail duplicado: ${dados.email}`, data: new Date().toISOString() });
  return alertas;
}

function buscarPorCriterio(tipo, valor) {
  switch(tipo) {
    case 'email': return usuarios.filter(u => u.email.includes(valor));
    case 'nome': return usuarios.filter(u => u.nome.includes(valor));
    default: return usuarios;
  }
}

module.exports = { verificarDuplicidade, buscarPorCriterio };
