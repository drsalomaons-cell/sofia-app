const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname);
const USERS_FILE = path.join(DATA_DIR, 'usuarios.json');
const LOGS_FILE = path.join(DATA_DIR, 'logs.json');
const DEVICES_FILE = path.join(DATA_DIR, 'dispositivos.json');

let usuarios = [];
let logs = [];
let dispositivos = [];

function carregarDados() {
  try {
    if (fs.existsSync(USERS_FILE)) usuarios = JSON.parse(fs.readFileSync(USERS_FILE, 'utf8'));
    if (fs.existsSync(LOGS_FILE)) logs = JSON.parse(fs.readFileSync(LOGS_FILE, 'utf8'));
    if (fs.existsSync(DEVICES_FILE)) dispositivos = JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
  } catch(e) { console.log('📂 Arquivos novos criados'); }
}

function salvarDados() {
  fs.writeFileSync(USERS_FILE, JSON.stringify(usuarios, null, 2));
  fs.writeFileSync(LOGS_FILE, JSON.stringify(logs, null, 2));
  fs.writeFileSync(DEVICES_FILE, JSON.stringify(dispositivos, null, 2));
}

function hashSenha(senha) {
  const crypto = require('crypto');
  return crypto.createHash('sha256').update(senha).digest('hex');
}

carregarDados();

if (!usuarios.find(u => u.email === 'admin@sofia.com')) {
  usuarios.push({
    id: 'admin-001',
    nome: 'Administrador Central',
    email: 'admin@sofia.com',
    senha: hashSenha('123456'),
    nivel: 'central',
    regiao: 'todas',
    ativo: true,
    criadoEm: new Date().toISOString()
  });
  salvarDados();
  console.log('✅ Usuário criado: admin@sofia.com / 123456');
}

module.exports = {
  usuarios, logs, dispositivos,
  salvarDados, carregarDados, hashSenha
};
