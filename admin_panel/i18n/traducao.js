const TRADUCOES = {
  pt: { bemvindo: 'Bem-vindo', usuarios: 'Usuários', sair: 'Sair' },
  en: { bemvindo: 'Welcome', usuarios: 'Users', sair: 'Logout' }
};

function detectarIdioma(cabecalho) {
  if (!cabecalho) return 'pt';
  if (cabecalho.includes('en')) return 'en';
  return 'pt';
}

module.exports = { TRADUCOES, detectarIdioma };
