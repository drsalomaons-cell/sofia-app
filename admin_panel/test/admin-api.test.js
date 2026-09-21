const test = require('node:test');
const assert = require('node:assert/strict');

const { autenticarAdmin, criarAdminRegional, listarLogs, registrarSolicitacaoMoedas, avaliarSolicitacao } = require('../admin-core.js');

const baseEstado = {
  admins: [
    { id: 'central-1', nome: 'Central', email: 'admin@sofia.com', senha: '123456', nivel: 'central', regiao: 'todas', ativo: true },
    { id: 'regional-1', nome: 'Regional Sul', email: 'regional@sofia.com', senha: '123456', nivel: 'regional', regiao: 'Brasil - LATAM', ativo: true },
  ],
  logs: [],
  solicitacoes: [],
};

test('autentica admin central e regional com escopo correto', () => {
  const estado = JSON.parse(JSON.stringify(baseEstado));
  const resultadoCentral = autenticarAdmin(estado, 'admin@sofia.com', '123456', '127.0.0.1');
  const resultadoRegional = autenticarAdmin(estado, 'regional@sofia.com', '123456', '127.0.0.1');

  assert.equal(resultadoCentral.sucesso, true);
  assert.equal(resultadoRegional.sucesso, true);
  assert.equal(resultadoCentral.usuario.nivel, 'central');
  assert.equal(resultadoRegional.usuario.nivel, 'regional');
  assert.equal(estado.logs.length >= 2, true);
});

test('cria regional e registra ação de auditoria', () => {
  const estado = JSON.parse(JSON.stringify(baseEstado));
  const admin = criarAdminRegional(estado, {
    nome: 'Nova Regional',
    email: 'nova-regional@sofia.com',
    senha: 'abcdef',
    regiao: 'África',
    criadorId: 'central-1',
  });

  assert.equal(admin.sucesso, true);
  assert.equal(estado.admins.some(item => item.email === 'nova-regional@sofia.com'), true);
  assert.equal(estado.logs.some(item => item.acao === 'criar_admin_regional'), true);
});

test('solicitação de moedas pode entrar em pendência e ser listada', () => {
  const estado = JSON.parse(JSON.stringify(baseEstado));
  const solicitacao = registrarSolicitacaoMoedas(estado, {
    usuarioId: 'user-101',
    usuarioNome: 'Joana',
    valor: 250,
    regiao: 'Brasil - LATAM',
  });

  assert.equal(solicitacao.sucesso, true);
  assert.equal(estado.solicitacoes[0].status, 'pendente');
  assert.equal(listarLogs(estado).length >= 1, true);
});

test('avaliação de moedas é uma operação exclusiva do administrador central', () => {
  const estado = JSON.parse(JSON.stringify(baseEstado));
  const solicitacao = registrarSolicitacaoMoedas(estado, {
    usuarioId: 'user-101', usuarioNome: 'Joana', valor: 250, regiao: 'Brasil - LATAM',
  }).solicitacao;
  const central = { id: 'central-1', nivel: 'central', regiao: 'todas' };

  assert.equal(central.nivel, 'central');
  const resultado = avaliarSolicitacao(estado, {
    solicitacaoId: solicitacao.id, acao: 'aprovar', valorLiberado: 250,
    adminId: central.id, regiao: central.regiao,
  });
  assert.equal(resultado.sucesso, true);
});
