const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_FILE = path.join(__dirname, 'data', 'admin-state.json');

function hashSenha(senha) {
  return crypto.createHash('sha256').update(String(senha)).digest('hex');
}

function senhaValida(senhaArmazenada, senhaDigitada) {
  if (!senhaArmazenada || !senhaDigitada) return false;
  const senhaTexto = String(senhaDigitada);
  return senhaArmazenada === senhaTexto || hashSenha(senhaTexto) === senhaArmazenada;
}

function carregarEstado() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const conteudo = fs.readFileSync(DATA_FILE, 'utf8');
      if (conteudo.trim()) {
        const parsed = JSON.parse(conteudo);
        if (parsed && Array.isArray(parsed.admins)) return parsed;
      }
    }
  } catch (error) {
    console.warn('⚠️ Falha ao ler estado administrativo:', error.message);
  }

  const estadoInicial = {
    admins: [
      {
        id: 'admin-central-01',
        nome: 'Administrador Central',
        email: 'admin@sofia.com',
        senha: hashSenha('123456'),
        nivel: 'central',
        regiao: 'todas',
        ativo: true,
        criadoEm: new Date().toISOString(),
      },
      {
        id: 'admin-regional-br-01',
        nome: 'Maria Silva',
        email: 'regional.brasil@sofia.com',
        senha: hashSenha('123456'),
        nivel: 'regional',
        regiao: 'Brasil - LATAM',
        ativo: true,
        criadoEm: new Date().toISOString(),
      },
    ],
    logs: [],
    solicitacoes: [],
    moderacao: [],
    mensagens: [
      {
        id: 'msg-01',
        usuarioId: 'user-1001',
        usuarioNome: 'Ana Souza',
        regiao: 'Brasil - LATAM',
        conteudo: 'Mensagem apagada pelo usuário no aparelho',
        apagada: true,
        createdAt: new Date().toISOString(),
      },
      {
        id: 'msg-02',
        usuarioId: 'user-1002',
        usuarioNome: 'Pedro Nunes',
        regiao: 'Estados Unidos',
        conteudo: 'Mensagem ativa e visível no servidor',
        apagada: false,
        createdAt: new Date().toISOString(),
      },
    ],
    usuarios: [
      { id: 'user-1001', nome: 'Ana Souza', regiao: 'Brasil - LATAM', status: 'ativo' },
      { id: 'user-1002', nome: 'Pedro Nunes', regiao: 'Estados Unidos', status: 'ativo' },
    ],
  };

  salvarEstado(estadoInicial);
  return estadoInicial;
}

function salvarEstado(estado) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(estado, null, 2));
}

function registrarLog(estado, usuarioId, acao, detalhe = {}, ip = 'local', regiao = 'global') {
  const entrada = {
    id: `log-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
    usuarioId,
    acao,
    detalhe,
    regiao,
    ip,
    data: new Date().toISOString(),
  };

  estado.logs.unshift(entrada);
  if (estado.logs.length > 2000) estado.logs = estado.logs.slice(0, 2000);
  salvarEstado(estado);
  return entrada;
}

function autenticarAdmin(estado, email, senha, ip = 'local') {
  const emailBusca = String(email || '').trim().toLowerCase();
  const usuario = estado.admins.find((admin) => admin.email.toLowerCase() === emailBusca && admin.ativo);

  if (!usuario) {
    return { sucesso: false, erro: 'E-mail ou senha incorretos' };
  }

  if (!senhaValida(usuario.senha, senha)) {
    return { sucesso: false, erro: 'E-mail ou senha incorretos' };
  }

  registrarLog(estado, usuario.id, 'login', { email: usuario.email, nivel: usuario.nivel }, ip, usuario.regiao);

  return {
    sucesso: true,
    usuario: {
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      nivel: usuario.nivel,
      regiao: usuario.regiao,
    },
  };
}

function listarAdmins(estado, usuarioViewer = null) {
  const admins = estado.admins.map((admin) => ({
    id: admin.id,
    nome: admin.nome,
    email: admin.email,
    nivel: admin.nivel,
    regiao: admin.regiao,
    ativo: admin.ativo,
    criadoEm: admin.criadoEm,
  }));

  if (!usuarioViewer || usuarioViewer.nivel !== 'regional') return admins;
  return admins.filter((admin) => admin.regiao === usuarioViewer.regiao || admin.id === usuarioViewer.id);
}

function criarAdminRegional(estado, { nome, email, senha, regiao, criadorId, ip = 'local' }) {
  if (!nome || !email || !senha || !regiao) {
    return { sucesso: false, erro: 'Preencha nome, e-mail, senha e região.' };
  }

  const emailNormalizado = String(email).trim().toLowerCase();
  if (estado.admins.some((admin) => admin.email.toLowerCase() === emailNormalizado)) {
    return { sucesso: false, erro: 'E-mail já cadastrado no painel.' };
  }

  const novoAdmin = {
    id: `admin-regional-${Date.now()}`,
    nome: String(nome).trim(),
    email: emailNormalizado,
    senha: hashSenha(String(senha)),
    nivel: 'regional',
    regiao: String(regiao).trim(),
    ativo: true,
    criadoEm: new Date().toISOString(),
  };

  estado.admins.push(novoAdmin);
  registrarLog(estado, criadorId || 'system', 'criar_admin_regional', {
    nome: novoAdmin.nome,
    email: novoAdmin.email,
    regiao: novoAdmin.regiao,
  }, ip, 'todas');

  return { sucesso: true, admin: { ...novoAdmin, senha: undefined } };
}

function atualizarAdmin(estado, { adminId, nome, email, regiao, ativo, editorId = 'system', ip = 'local' }) {
  const admin = estado.admins.find((item) => item.id === adminId);
  if (!admin) {
    return { sucesso: false, erro: 'Administrador não encontrado.' };
  }

  if (nome && String(nome).trim()) admin.nome = String(nome).trim();

  if (email) {
    const emailNormalizado = String(email).trim().toLowerCase();
    const duplicado = estado.admins.some(
      (item) => item.id !== adminId && item.email && item.email.toLowerCase() === emailNormalizado
    );
    if (duplicado) {
      return { sucesso: false, erro: 'E-mail já cadastrado no painel.' };
    }
    admin.email = emailNormalizado;
  }

  if (regiao && String(regiao).trim()) {
    admin.regiao = String(regiao).trim();
  }

  if (typeof ativo === 'boolean') {
    admin.ativo = ativo;
  }

  registrarLog(estado, editorId, 'atualizar_admin', {
    adminId: admin.id,
    nome: admin.nome,
    email: admin.email,
    regiao: admin.regiao,
    ativo: admin.ativo,
  }, ip, admin.regiao);

  return { sucesso: true, admin: { ...admin, senha: undefined } };
}

function redefinirSenhaAdmin(estado, { adminId, novaSenha, editorId = 'system', ip = 'local' }) {
  const admin = estado.admins.find((item) => item.id === adminId);
  if (!admin) {
    return { sucesso: false, erro: 'Administrador não encontrado.' };
  }

  if (!novaSenha || String(novaSenha).trim().length < 6) {
    return { sucesso: false, erro: 'A senha deve ter pelo menos 6 caracteres.' };
  }

  admin.senha = hashSenha(String(novaSenha));
  registrarLog(estado, editorId, 'redefinir_senha', {
    adminId: admin.id,
    nome: admin.nome,
    regiao: admin.regiao,
  }, ip, admin.regiao);

  return { sucesso: true, admin: { id: admin.id, nome: admin.nome, regiao: admin.regiao } };
}

function listarSolicitacoes(estado, usuarioViewer = null) {
  const solicitacoes = [...estado.solicitacoes].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  if (!usuarioViewer || usuarioViewer.nivel !== 'regional') return solicitacoes;
  return solicitacoes.filter((item) => item.regiao === usuarioViewer.regiao);
}

function registrarSolicitacaoMoedas(estado, { usuarioId, usuarioNome, valor, regiao, ip = 'local' }) {
  const valorNumerico = Number(valor || 0);
  const solicitacao = {
    id: `solicitacao-${Date.now()}`,
    usuarioId,
    usuarioNome: usuarioNome || 'Usuário',
    valor: valorNumerico,
    regiao,
    status: 'pendente',
    createdAt: new Date().toISOString(),
    observacao: 'Aguardando aprovação do administrador',
  };

  estado.solicitacoes.unshift(solicitacao);
  registrarLog(estado, 'system', 'solicitacao_moedas', {
    usuarioId,
    usuarioNome: solicitacao.usuarioNome,
    valor: solicitacao.valor,
    regiao,
    status: solicitacao.status,
  }, ip, regiao);

  return { sucesso: true, solicitacao };
}

function avaliarSolicitacao(estado, { solicitacaoId, acao, valorLiberado, adminId, ip = 'local', regiao }) {
  const solicitacao = estado.solicitacoes.find((item) => item.id === solicitacaoId);
  if (!solicitacao) {
    return { sucesso: false, erro: 'Solicitação não encontrada.' };
  }

  const decisao = String(acao || '').toLowerCase();
  const valorFinal = Number(valorLiberado || solicitacao.valor || 0);

  solicitacao.status = decisao === 'aprovar' ? 'aprovada' : 'rejeitada';
  solicitacao.valorLiberado = valorFinal;
  solicitacao.adminId = adminId;
  solicitacao.updatedAt = new Date().toISOString();
  solicitacao.observacao = decisao === 'aprovar' ? 'Moedas liberadas' : 'Solicitação rejeitada';

  registrarLog(estado, adminId, 'liberacao_moedas', {
    solicitacaoId: solicitacao.id,
    usuarioNome: solicitacao.usuarioNome,
    valorLiberado: valorFinal,
    status: solicitacao.status,
  }, ip, regiao || solicitacao.regiao);

  return { sucesso: true, solicitacao };
}

function listarLogs(estado, usuarioViewer = null) {
  const logs = [...estado.logs];
  if (!usuarioViewer || usuarioViewer.nivel !== 'regional') return logs;
  return logs.filter((log) => log.regiao === usuarioViewer.regiao || log.usuarioId === usuarioViewer.id);
}

function listarModeracao(estado, usuarioViewer = null) {
  const lista = [...estado.moderacao];
  if (!usuarioViewer || usuarioViewer.nivel !== 'regional') return lista;
  return lista.filter((item) => item.regiao === usuarioViewer.regiao);
}

function registrarAlertaModeracao(estado, { tipo, descricao, usuarioId, regiao, ip = 'local' }) {
  const alerta = {
    id: `mod-${Date.now()}`,
    tipo,
    descricao,
    usuarioId,
    regiao,
    status: 'pendente',
    createdAt: new Date().toISOString(),
  };

  estado.moderacao.unshift(alerta);
  registrarLog(estado, 'system', 'alerta_moderacao', { tipo, descricao, usuarioId, regiao }, ip, regiao);
  return { sucesso: true, alerta };
}

function listarMensagens(estado, usuarioViewer = null) {
  const mensagens = [...estado.mensagens].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  if (!usuarioViewer || usuarioViewer.nivel !== 'regional') return mensagens;
  return mensagens.filter((item) => item.regiao === usuarioViewer.regiao);
}

function recuperarMensagem(estado, mensagemId, usuarioViewer, ip = 'local') {
  const mensagem = estado.mensagens.find((item) => item.id === mensagemId);
  if (!mensagem) return { sucesso: false, erro: 'Mensagem não encontrada.' };
  mensagem.recuperada = true;
  mensagem.recuperadaPor = usuarioViewer?.id || 'system';
  mensagem.recuperadaEm = new Date().toISOString();

  registrarLog(estado, usuarioViewer?.id || 'system', 'recuperar_mensagem', {
    mensagemId: mensagem.id,
    usuarioNome: mensagem.usuarioNome,
    regiao: mensagem.regiao,
  }, ip, mensagem.regiao);

  return { sucesso: true, mensagem };
}

module.exports = {
  carregarEstado,
  salvarEstado,
  hashSenha,
  autenticarAdmin,
  listarAdmins,
  criarAdminRegional,
  atualizarAdmin,
  redefinirSenhaAdmin,
  listarSolicitacoes,
  registrarSolicitacaoMoedas,
  avaliarSolicitacao,
  listarLogs,
  registrarAlertaModeracao,
  listarModeracao,
  listarMensagens,
  recuperarMensagem,
  registrarLog,
};
