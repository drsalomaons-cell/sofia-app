const express = require('express');
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORTA = 3000;
const sessions = new Map();

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const {
  carregarEstado,
  autenticarAdmin,
  listarAdmins,
  criarAdminRegional,
  atualizarAdmin,
  redefinirSenhaAdmin,
  listarSolicitacoes,
  registrarSolicitacaoMoedas,
  avaliarSolicitacao,
  listarLogs,
  listarModeracao,
  registrarAlertaModeracao,
  listarMensagens,
  recuperarMensagem,
  registrarLog,
} = require('./admin-core');

function getViewer(req) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : null;
  if (!token) return null;
  const session = sessions.get(token);
  return session ? session.usuario : null;
}

function requireAdmin(req, res, next) {
  const viewer = getViewer(req);
  if (!viewer) {
    return res.status(401).json({ sucesso: false, erro: 'Sessão expirada ou não autenticada.' });
  }
  req.viewer = viewer;
  next();
}

function withState(fn) {
  return (req, res) => {
    const estado = carregarEstado();
    fn(req, res, estado);
  };
}

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/painel-administracao.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'painel-administracao.html'));
});

app.post('/api/admin/login', withState((req, res, estado) => {
  const { email, senha } = req.body || {};
  const resultado = autenticarAdmin(estado, email, senha, req.ip);

  if (!resultado.sucesso) {
    return res.status(401).json(resultado);
  }

  const token = crypto.randomUUID();
  sessions.set(token, { usuario: resultado.usuario, createdAt: Date.now() });

  return res.json({
    sucesso: true,
    token,
    usuario: resultado.usuario,
  });
}));

app.post('/api/admin/logout', requireAdmin, (req, res) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : null;
  if (token) sessions.delete(token);
  res.json({ sucesso: true, mensagem: 'Sessão encerrada.' });
});

app.get('/api/admin/dashboard', requireAdmin, withState((req, res, estado) => {
  const viewer = req.viewer;
  const admins = listarAdmins(estado, viewer);
  const solicitacoes = listarSolicitacoes(estado, viewer);
  const logs = listarLogs(estado, viewer);
  const moderacao = listarModeracao(estado, viewer);
  const mensagens = listarMensagens(estado, viewer);

  res.json({
    sucesso: true,
    dados: {
      usuario: viewer,
      admins,
      solicitacoes,
      logs: logs.slice(0, 80),
      moderacao: moderacao.slice(0, 40),
      mensagens: mensagens.slice(0, 40),
      usuarios: estado.usuarios || [],
      resumo: {
        adminsAtivos: admins.filter((admin) => admin.ativo).length,
        regioes: [...new Set(admins.map((admin) => admin.regiao))].length,
        solicitacoesPendentes: solicitacoes.filter((item) => item.status === 'pendente').length,
        alerts: moderacao.filter((item) => item.status === 'pendente').length,
      },
    },
  });
}));

app.get('/api/admin/usuarios', requireAdmin, withState((req, res, estado) => {
  const dados = listarAdmins(estado, req.viewer);
  res.json({ sucesso: true, dados });
}));

app.post('/api/admin/admins', requireAdmin, withState((req, res, estado) => {
  if (req.viewer.nivel !== 'central') {
    return res.status(403).json({ sucesso: false, erro: 'Apenas o administrador central pode criar regionais.' });
  }

  const resultado = criarAdminRegional(estado, {
    nome: req.body.nome,
    email: req.body.email,
    senha: req.body.senha,
    regiao: req.body.regiao,
    criadorId: req.viewer.id,
    ip: req.ip,
  });

  if (!resultado.sucesso) {
    return res.status(400).json(resultado);
  }

  return res.status(201).json(resultado);
}));

app.put('/api/admin/admins/:id', requireAdmin, withState((req, res, estado) => {
  const viewer = req.viewer;
  const targetId = req.params.id;

  if (viewer.nivel !== 'central' && viewer.id !== targetId) {
    return res.status(403).json({ sucesso: false, erro: 'Você só pode alterar o próprio perfil.' });
  }

  const resultado = atualizarAdmin(estado, {
    adminId: targetId,
    nome: req.body.nome,
    email: req.body.email,
    regiao: req.body.regiao,
    ativo: req.body.ativo,
    editorId: viewer.id,
    ip: req.ip,
  });

  if (!resultado.sucesso) {
    return res.status(400).json(resultado);
  }

  return res.json({ sucesso: true, dados: resultado.admin });
}));

app.post('/api/admin/admins/:id/redefinir-senha', requireAdmin, withState((req, res, estado) => {
  const viewer = req.viewer;
  const targetId = req.params.id;

  if (viewer.nivel !== 'central' && viewer.id !== targetId) {
    return res.status(403).json({ sucesso: false, erro: 'Você só pode redefinir a própria senha.' });
  }

  const resultado = redefinirSenhaAdmin(estado, {
    adminId: targetId,
    novaSenha: req.body.novaSenha,
    editorId: viewer.id,
    ip: req.ip,
  });

  if (!resultado.sucesso) {
    return res.status(400).json(resultado);
  }

  return res.json({ sucesso: true, dados: resultado.admin });
}));

app.post('/api/admin/admins/:id/desativar', requireAdmin, withState((req, res, estado) => {
  const viewer = req.viewer;
  const targetId = req.params.id;

  if (viewer.nivel !== 'central' && viewer.id !== targetId) {
    return res.status(403).json({ sucesso: false, erro: 'Você só pode desativar o próprio acesso.' });
  }

  const resultado = atualizarAdmin(estado, {
    adminId: targetId,
    ativo: false,
    editorId: viewer.id,
    ip: req.ip,
  });

  if (!resultado.sucesso) {
    return res.status(400).json(resultado);
  }

  return res.json({ sucesso: true, dados: resultado.admin });
}));

app.get('/api/admin/solicitacoes', requireAdmin, withState((req, res, estado) => {
  res.json({ sucesso: true, dados: listarSolicitacoes(estado, req.viewer) });
}));

app.post('/api/admin/solicitacoes/:id/avaliar', requireAdmin, withState((req, res, estado) => {
  const viewer = req.viewer;
  if (viewer.nivel !== 'central') {
    return res.status(403).json({ sucesso: false, erro: 'Apenas o administrador central pode aprovar ou rejeitar moedas.' });
  }
  const { acao, valorLiberado } = req.body || {};
  const resultado = avaliarSolicitacao(estado, {
    solicitacaoId: req.params.id,
    acao,
    valorLiberado,
    adminId: viewer.id,
    ip: req.ip,
    regiao: viewer.regiao,
  });

  if (!resultado.sucesso) {
    return res.status(400).json(resultado);
  }

  return res.json({ sucesso: true, dados: resultado.solicitacao });
}));

app.post('/api/admin/solicitacoes', requireAdmin, withState((req, res, estado) => {
  const viewer = req.viewer;
  const { usuarioId, usuarioNome, valor, regiao } = req.body || {};
  const resultado = registrarSolicitacaoMoedas(estado, {
    usuarioId,
    usuarioNome,
    valor,
    regiao: regiao || viewer.regiao,
    ip: req.ip,
  });
  return res.status(201).json(resultado);
}));

app.get('/api/admin/logs', requireAdmin, withState((req, res, estado) => {
  res.json({ sucesso: true, dados: listarLogs(estado, req.viewer) });
}));

app.get('/api/admin/moderacao', requireAdmin, withState((req, res, estado) => {
  res.json({ sucesso: true, dados: listarModeracao(estado, req.viewer) });
}));

app.post('/api/admin/moderacao', requireAdmin, withState((req, res, estado) => {
  const resultado = registrarAlertaModeracao(estado, {
    tipo: req.body.tipo,
    descricao: req.body.descricao,
    usuarioId: req.body.usuarioId,
    regiao: req.body.regiao || req.viewer.regiao,
    ip: req.ip,
  });
  return res.status(201).json(resultado);
}));

app.get('/api/admin/mensagens', requireAdmin, withState((req, res, estado) => {
  res.json({ sucesso: true, dados: listarMensagens(estado, req.viewer) });
}));

app.post('/api/admin/mensagens/:id/recuperar', requireAdmin, withState((req, res, estado) => {
  if (req.viewer.nivel !== 'central') {
    return res.status(403).json({ sucesso: false, erro: 'Apenas o administrador central pode recuperar mensagens.' });
  }
  const resultado = recuperarMensagem(estado, req.params.id, req.viewer, req.ip);
  if (!resultado.sucesso) {
    return res.status(404).json(resultado);
  }
  return res.json(resultado);
}));

app.listen(PORTA, '0.0.0.0', () => {
  console.log('========================================');
  console.log('🚀 PAINEL ADMIN SOFIA ATIVO');
  console.log('📧 Usuário central: admin@sofia.com');
  console.log('🔑 Senha: 123456');
  console.log('🌐 http://localhost:3000');
  console.log('========================================');
});
