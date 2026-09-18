const NIVEIS = { central: 'Admin Central', regional: 'Admin Regional', usuario: 'Usuário' };

function verificarPermissao(usuario, regiaoAlvo) {
  if (usuario.nivel === 'central') return true;
  return usuario.regiao === regiaoAlvo;
}

module.exports = { NIVEIS, verificarPermissao };
