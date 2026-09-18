const express = require('express');
const path = require('path');
const app = express();
const PORTA = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const store = require('./data/store');
const auditoria = require('./routes/auditoria');

// Página única — login + painel juntos
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API de login
app.post('/api/admin/login', (req, res) => {
  const { email, senha } = req.body;
  const usuario = store.usuarios.find(u => u.email === email && u.ativo);
  
  if (usuario && store.hashSenha(senha) === usuario.senha) {
    auditoria.registrarAcao(usuario.id, 'login', req.ip);
    res.json({ 
      sucesso: true, 
      usuario: { 
        id: usuario.id, 
        nome: usuario.nome, 
        email: usuario.email, 
        nivel: usuario.nivel 
      }
    });
  } else {
    res.status(401).json({ sucesso: false, erro: 'E-mail ou senha incorretos' });
  }
});

// Lista de usuários
app.get('/api/admin/usuarios', (req, res) => {
  res.json({ sucesso: true, dados: store.usuarios });
});

app.listen(PORTA, '0.0.0.0', () => {
  console.log('========================================');
  console.log('🚀 SISTEMA SIMPLIFICADO — PRONTO!');
  console.log('📧 Login: admin@sofia.com');
  console.log('🔑 Senha: 123456');
  console.log('🌐 http://localhost:3000');
  console.log('========================================');
});
