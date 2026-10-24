process.env.ADMIN_CENTRAL_PASSWORD = 'supersecretadminpassword123!';
const test = require('node:test');
const assert = require('node:assert');
const store = require('../data/store');

test('Fase 1 - Persistência de frame, avatar e capa no store', async () => {
  const users = store.getUsers();
  const testUserId = 'test-fase1-user';
  
  // Cria usuário de teste
  const user = {
    id: testUserId,
    name: 'Sofia Tester',
    email: 'tester@sofia.app',
    gender: 'Feminino',
    frame: 'baby_a',
    frameId: 'baby_a',
    coverUrl: '',
    photoUrl: '',
    gallery: [],
    balance: 500,
    coins: 500,
    diamonds: 50,
    level: 2,
    createdAt: new Date().toISOString(),
  };

  users.push(user);
  store.saveUsers(users);

  // 1. Testa equipagem de moldura
  const loaded = store.findUser(testUserId);
  assert.ok(loaded);
  assert.strictEqual(loaded.frame, 'baby_a');

  // Atualiza moldura para official_admin_a
  const allUsers = store.getUsers();
  const idx = allUsers.findIndex(u => u.id === testUserId);
  allUsers[idx].frame = 'official_admin_a';
  allUsers[idx].frameId = 'official_admin_a';
  allUsers[idx].coverUrl = '/storage/uploads/covers/test_cover.jpg';
  allUsers[idx].photoUrl = '/storage/uploads/avatars/test_avatar.jpg';
  allUsers[idx].gallery = ['/storage/uploads/gallery/photo1.jpg'];
  store.saveUsers(allUsers);

  // Recarrega e valida
  const updated = store.findUser(testUserId);
  assert.strictEqual(updated.frame, 'official_admin_a');
  assert.strictEqual(updated.frameId, 'official_admin_a');
  assert.strictEqual(updated.coverUrl, '/storage/uploads/covers/test_cover.jpg');
  assert.strictEqual(updated.photoUrl, '/storage/uploads/avatars/test_avatar.jpg');
  assert.strictEqual(updated.gallery.length, 1);
  assert.strictEqual(updated.gallery[0], '/storage/uploads/gallery/photo1.jpg');

  // Valida publicAppUser
  const publicData = store.publicAppUser(updated);
  assert.strictEqual(publicData.frame, 'official_admin_a');
  assert.strictEqual(publicData.coverUrl, '/storage/uploads/covers/test_cover.jpg');

  // Limpa usuário de teste
  const cleaned = store.getUsers().filter(u => u.id !== testUserId);
  store.saveUsers(cleaned);
});
