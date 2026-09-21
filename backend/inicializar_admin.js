const bcrypt = require('bcryptjs');
const fs = require('fs');
const caminho = __dirname + '/data/users.json';

const usuarios = [
  {
    id: 'admin-sofia-001',
    name: 'Admin Sofia',
    email: 'admin@sofia.com.br',
    password: bcrypt.hashSync('123456', 10),
    isAdmin: true,
    role: 'ADMIN_CENTRAL',
    createdAt: new Date().toISOString()
  }
];

if (!fs.existsSync(__dirname + '/data')) fs.mkdirSync(__dirname + '/data', { recursive: true });
fs.writeFileSync(caminho, JSON.stringify(usuarios, null, 2));
console.log('✅ Usuário admin criado com sucesso!');
console.log('📧 E-mail: admin@sofia.com.br');
console.log('🔑 Senha:  123456');
