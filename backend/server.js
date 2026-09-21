const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: "*" } });

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'sofia_segredo_2026';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../admin_panel/public')));

let users = [
  {
    id: 'admin-sofia-001',
    name: 'Admin Sofia',
    email: 'admin@sofia.com.br',
    password: '$2a$10$EixZaYb4xU58Gpq1R0yWbeb00LU5qUaK6x9Q6H3u7vT6Pn5qz7r6m',
    isAdmin: true,
    role: 'ADMIN_CENTRAL',
    createdAt: new Date().toISOString()
  }
];

const hashSenha = async (senha) => await bcrypt.hash(senha, 10);
const comparaSenha = async (entrada, salva) => await bcrypt.compare(entrada, salva);

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  const usuario = users.find(u => u.email === email);
  if (!usuario) return res.status(401).json({ erro: 'Usuário não encontrado' });
  if (!(await comparaSenha(password, usuario.password))) {
    return res.status(401).json({ erro: 'Senha incorreta' });
  }
  const token = jwt.sign(
    { id: usuario.id, email: usuario.email, role: usuario.role },
    JWT_SECRET,
    { expiresIn: '24h' }
  );
  res.json({
    token,
    usuario: {
      id: usuario.id,
      name: usuario.name,
      email: usuario.email,
      isAdmin: usuario.isAdmin,
      role: usuario.role
    }
  });
});

app.get('/api/verificar', (req, res) => {
  res.json({ ok: true, mensagem: 'Servidor SOFIA funcionando!', porta: PORT });
});

app.get('/api/admin/usuarios', (req, res) => {
  res.json(users.map(u => ({ ...u, password: undefined })));
});

io.on('connection', (socket) => {
  console.log('✅ Cliente conectado:', socket.id);
  socket.on('disconnect', () => console.log('❌ Cliente desconectado:', socket.id));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║          ✅ SERVIDOR SOFIA — LIGADO COM SUCESSO!          ║');
  console.log('╠══════════════════════════════════════════════════════════╣');
  console.log(`║  📡 Servidor:    http://192.168.0.248:${PORT}                ║`);
  console.log(`║  🖥️  Painel Web:  http://192.168.0.248:${PORT}/admin         ║`);
  console.log('╠══════════════════════════════════════════════════════════╣');
  console.log('║  👤 LOGIN ADMINISTRADOR:                                 ║');
  console.log('║     E-mail: admin@sofia.com.br                           ║');
  console.log('║     Senha:  123456                                       ║');
  console.log('╚══════════════════════════════════════════════════════════╝');
  console.log('');
});
