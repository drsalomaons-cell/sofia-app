const crypto = require('crypto');
const store = require('../data/store');
const { hashPassword } = require('../auth/password');
const economy = require('../economy/engine');
const fraud = require('../fraud/detector');
const roles = require('../auth/roles');
const { moderateContent } = require('../moderation/filter');
const { requireAdmin } = require('../auth/admin_session');
const { loadEconomyConfig, saveEconomyConfig } = require('../economy/store');
const pagbank = require('../services/pagbank');
const zego = require('../services/zego');
const { syncUserLevelsAndVip } = require('../jobs/scheduler');

function txId() {
  return crypto.randomBytes(8).toString('hex');
}

const APP_GIFT_CATALOG = [
  { id: 'rose', name: 'Rosa', price: 10, tier: 'common', emoji: '🌹' },
  { id: 'heart', name: 'Coração', price: 30, tier: 'common', emoji: '💖' },
  { id: 'star', name: 'Estrela', price: 50, tier: 'rare', emoji: '⭐' },
  { id: 'frame', name: 'Moldura', price: 120, tier: 'rare', emoji: '🖼️' },
  { id: 'crown', name: 'Coroa', price: 200, tier: 'epic', emoji: '👑' },
  { id: 'car', name: 'Carro VIP', price: 350, tier: 'epic', emoji: '🚗' },
  { id: 'rocket', name: 'Foguete', price: 500, tier: 'legendary', emoji: '🚀' },
  { id: 'trophy', name: 'Troféu', price: 800, tier: 'legendary', emoji: '🏆' },
  { id: 'diamond', name: 'Diamante', price: 1000, tier: 'mythic', emoji: '💎' },
];

function mountApiRoutes(app) {
  loadEconomyConfig();

  // ── Auth ──
  app.post('/api/auth/login', (req, res) => {
    const { email, password } = req.body;
    const user = store.findUserByEmail(email);
    if (!user || !store.verifyUserPassword(user, password)) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }
    if (store.isAdminAccount(user)) {
      return res.status(403).json({
        error: 'Acesso administrativo disponível apenas no painel web',
        adminPanelUrl: 'https://sofia-app-yhzb.onrender.com/admin',
      });
    }
    res.json({ user: store.publicAppUser(user), token: user.id });
  });

  app.post('/api/auth/register', (req, res) => {
    const { name, email, phone, password, gender, interestedIn, region } = req.body;
    if (store.findUserByEmail(email)) {
      return res.status(400).json({ error: 'E-mail já cadastrado' });
    }
    const user = {
      id: txId(),
      name,
      email,
      phone,
      passwordHash: hashPassword(password),
      gender,
      interestedIn,
      region: region || 'América do Sul',
      balance: 0,
      level: 1,
      points: 0,
      xp: 0,
      referrals: 0,
      isAdmin: false,
      isRegionalAdmin: false,
      role: 'participant',
      createdAt: new Date().toISOString(),
    };
    const users = store.getUsers();
    users.push(user);
    store.saveUsers(users);
    res.json({ user: store.publicAppUser(user), token: user.id });
  });

  app.get('/api/auth/me/:userId', (req, res) => {
    const user = store.findUser(req.params.userId);
    if (!user) return res.status(404).json({ error: 'Usuário não encontrado' });
    res.json({ user: store.publicAppUser(user) });
  });
  app.get('/api/economy/rules', (_req, res) => {
    res.json(economy.getFullRules());
  });

  app.get('/api/admin/economy/config', requireAdmin, (_req, res) => {
    res.json({ config: economy.getConfig(), rules: economy.getFullRules() });
  });

  app.post('/api/admin/economy/config', requireAdmin, (req, res) => {
    const cfg = saveEconomyConfig({ ...economy.getConfig(), ...req.body });
    res.json({ success: true, config: cfg });
  });

  app.get('/api/wallet/:userId/balance', (req, res) => {
    const user = store.findUser(req.params.userId);
    if (!user) return res.status(404).json({ error: 'Usuário não encontrado' });
    const vip = economy.getVipTier(user.totalSpend || 0);
    const levelInfo = economy.getLevelInfo(user.level || 1);
    res.json({
      balance: user.balance,
      coins: user.coins ?? user.balance,
      diamonds: user.diamonds || 0,
      level: user.level,
      levelTitle: levelInfo.title,
      frame: user.frame || levelInfo.frame,
      vipTier: vip.id,
      vipTag: vip.tag,
      points: user.points,
      hostLevel: user.hostLevel || 0,
      hostSalary: economy.getHostSalary(user.hostLevel || 0),
    });
  });

  app.get('/api/wallet/:userId/transactions', (req, res) => {
    const txs = store.getTransactions().filter((t) => t.userId === req.params.userId);
    res.json({ transactions: txs });
  });

  app.post('/api/wallet/recharge', async (req, res) => {
    const { userId, amount, paymentMethod = 'PIX' } = req.body;
    const users = store.getUsers();
    const idx = users.findIndex((u) => u.id === userId);
    if (idx < 0) return res.status(404).json({ error: 'Usuário não encontrado' });

    const pendingId = txId();
    let paymentResult = { success: true, instantCredit: true, sandbox: true };
    if (paymentMethod === 'PIX') {
      paymentResult = await pagbank.createPixCharge({
        amount, userId, description: 'Recarga SOFIA', pendingId,
      });
    }
    if (!paymentResult.success) {
      return res.status(400).json({ error: paymentResult.error || 'Falha no PagBank' });
    }

    const shouldCredit = paymentResult.instantCredit !== false
      || paymentResult.status === 'PAID'
      || paymentResult.sandbox;

    let tx;
    if (shouldCredit) {
      users[idx] = economy.applyCoinsAndDiamonds(users[idx], { coins: amount });
      users[idx].totalSpend = (users[idx].totalSpend || 0) + amount;
      users[idx] = economy.addXp(users[idx], 5);
      syncUserLevelsAndVip();
      store.saveUsers(users);
      tx = store.addTransaction({
        id: txId(),
        userId,
        type: 'recharge',
        amount,
        description: `Recarga via ${paymentMethod}${paymentResult.sandbox ? ' (sandbox)' : ''}`,
        status: 'completed',
        paymentMethod,
        chargeId: paymentResult.chargeId,
        createdAt: new Date().toISOString(),
      });
    } else {
      tx = store.addTransaction({
        id: pendingId,
        userId,
        type: 'recharge',
        amount,
        description: `Recarga PIX aguardando confirmação`,
        status: 'pending',
        paymentMethod,
        chargeId: paymentResult.chargeId,
        createdAt: new Date().toISOString(),
      });
    }

    res.json({
      balance: users[idx].balance,
      coins: users[idx].coins,
      transaction: tx,
      payment: paymentResult,
      pending: !shouldCredit,
    });
  });

  app.post('/api/wallet/withdraw', async (req, res) => {
    const { userId, amount, pixKey, bankData } = req.body;
    const users = store.getUsers();
    const idx = users.findIndex((u) => u.id === userId);
    if (idx < 0) return res.status(404).json({ error: 'Usuário não encontrado' });

    const withdrawCalc = economy.processWithdraw(amount);
    const totalDebit = withdrawCalc.gross;

    const recentWithdraws = store.getTransactions().filter(
      (t) => t.userId === userId && t.type === 'withdraw' && Date.now() - new Date(t.createdAt).getTime() < 86400000
    ).length;

    const analysis = fraud.analyzeTransaction({
      withdrawAmount: totalDebit,
      balance: users[idx].balance,
      recentWithdraws,
    });
    if (analysis.blocked) {
      return res.status(403).json({ error: 'Saque bloqueado por segurança', analysis });
    }

    try {
      users[idx].balance = economy.applyBalanceChange(users[idx], -totalDebit).balance;
    } catch (e) {
      return res.status(400).json({ error: e.message });
    }
    store.saveUsers(users);

    const paymentResult = await pagbank.createPixWithdraw({
      amount: withdrawCalc.net,
      pixKey,
      userId,
    });

    const tx = store.addTransaction({
      id: txId(),
      userId,
      type: 'withdraw',
      amount: -totalDebit,
      description: `Saque PIX (taxa R$ ${withdrawCalc.fee} · ${withdrawCalc.processingDays} dias úteis)`,
      status: 'pending',
      pixKey,
      bankData,
      fee: withdrawCalc.fee,
      netAmount: withdrawCalc.net,
      estimatedCompletion: withdrawCalc.estimatedCompletion,
      createdAt: new Date().toISOString(),
    });

    res.json({
      balance: users[idx].balance,
      transaction: tx,
      withdraw: withdrawCalc,
      payment: paymentResult,
    });
  });

  app.post('/api/wallet/earning', (req, res) => {
    const {
      userId, roomId, roomName, totalAmount, source = 'room_time',
      participantCount = 1, isHost = false, roomGoalMet = false, isOpeningEvent = false,
    } = req.body;
    const users = store.getUsers();
    const idx = users.findIndex((u) => u.id === userId);
    if (idx < 0) return res.status(404).json({ error: 'Usuário não encontrado' });

    const vip = economy.getVipTier(users[idx].totalSpend || 0);
    const result = economy.processRoomEarning(totalAmount, participantCount, {
      isHost,
      roomGoalMet,
      vipTier: vip.id,
    });

    let bonus = result.perUser;
    if (isOpeningEvent) {
      const ev = economy.processOpeningEvent(participantCount, isHost);
      if (ev.granted) bonus += ev.bonus;
    }

    users[idx] = economy.applyCoinsAndDiamonds(users[idx], { coins: bonus });
    users[idx].points = (users[idx].points || 0) + Math.round(bonus);
    users[idx] = economy.addXp(users[idx], isHost ? 10 : 5);
    if (isHost) {
      users[idx].hostLevel = users[idx].hostLevel || 1;
      users[idx].hostPoints = (users[idx].hostPoints || 0) + Math.round(bonus);
    }
    store.saveUsers(users);

    const tx = store.addTransaction({
      id: txId(),
      userId,
      type: 'earning',
      amount: bonus,
      description: `Ganho (${source}): ${roomName} — ${result.description}`,
      roomId,
      roomName,
      status: 'completed',
      createdAt: new Date().toISOString(),
    });

    store.addTransaction({
      id: txId(),
      userId: 'platform',
      type: 'commission',
      amount: result.platform,
      description: `Comissão plataforma — ${roomName}`,
      roomId,
      status: 'completed',
      createdAt: new Date().toISOString(),
    });

    res.json({ balance: users[idx].balance, earning: { ...result, totalPaid: bonus }, transaction: tx });
  });

  // ── Rooms ──
  app.get('/api/rooms', (req, res) => {
    const region = req.query.region;
    const type = req.query.type === 'video' ? 'video' : (req.query.type === 'voice' ? 'voice' : null);
    let rooms = store.getRooms().filter((r) => r.isActive);
    if (region) rooms = rooms.filter((r) => r.region === region);
    // Salas antigas sem roomType permanecem como rádio para compatibilidade.
    if (type) rooms = rooms.filter((r) => (r.roomType || 'voice') === type);
    res.json({ rooms });
  });

  app.get('/api/rooms/:id', (req, res) => {
    const room = store.findRoom(req.params.id);
    if (!room) return res.status(404).json({ error: 'Sala não encontrada' });
    res.json({ room });
  });

  // Ranking real de contribuições por presentes enviados nesta sala.
  app.get('/api/rooms/:id/gift-ranking', (req, res) => {
    const room = store.findRoom(req.params.id);
    if (!room) return res.status(404).json({ error: 'Sala não encontrada' });
    const totals = new Map();
    for (const gift of store.getGiftLog().filter((entry) => entry.roomId === req.params.id)) {
      const senderId = gift.from || gift.senderId;
      if (!senderId) continue;
      const current = totals.get(senderId) || { userId: senderId, totalCoins: 0, giftCount: 0 };
      current.totalCoins += Number(gift.amount || 0);
      current.giftCount += 1;
      totals.set(senderId, current);
    }
    const usersById = new Map(store.getUsers().map((user) => [user.id, user]));
    const ranking = [...totals.values()]
      .map((entry) => {
        const user = usersById.get(entry.userId);
        return {
          ...entry,
          name: user?.name || 'Participante',
          photoUrl: user?.photoUrl || null,
        };
      })
      .sort((a, b) => b.totalCoins - a.totalCoins);
    res.json({ roomId: req.params.id, ranking });
  });

  app.get('/api/rooms/:id/rocket-goal', (req, res) => {
    const room = store.findRoom(req.params.id);
    if (!room) return res.status(404).json({ error: 'Sala não encontrada' });
    const goal = room.rocketGoal || {
      target: Number(economy.getConfig().roomGoalThreshold) || 400000,
      current: 0,
      contributors: {},
      metAt: null,
    };
    const usersById = new Map(store.getUsers().map((user) => [user.id, user]));
    const ranking = Object.entries(goal.contributors || {})
      .map(([userId, totalCoins]) => ({
        userId,
        name: usersById.get(userId)?.name || 'Participante',
        totalCoins: Number(totalCoins || 0),
      }))
      .sort((a, b) => b.totalCoins - a.totalCoins);
    const target = Number(goal.target || 400000);
    res.json({
      roomId: room.id,
      target,
      current: Number(goal.current || 0),
      progress: target > 0 ? Math.min(1, Number(goal.current || 0) / target) : 0,
      met: !!goal.metAt || Number(goal.current || 0) >= target,
      metAt: goal.metAt || null,
      topContributor: ranking[0] || null,
      ranking,
    });
  });

  app.post('/api/rooms', (req, res) => {
    const { name, description, theme, roomType, chairs, hostId, hostName, isPrivate, allowGuests, region, coverUrl } = req.body;
    const chairCount = Math.min(20, Math.max(4, chairs || 8));
    const room = {
      id: `room-${txId()}`,
      name,
      description: description || '',
      theme,
      roomType: roomType === 'video' ? 'video' : 'voice',
      coverUrl: coverUrl || '',
      chairs: chairCount,
      currentUsers: 1,
      isPrivate: !!isPrivate,
      allowGuests: allowGuests !== false,
      hostId,
      hostName,
      moderatorIds: [],
      participants: [hostId],
      bannedUsers: [],
      region: region || 'América do Sul',
      earnings: 0,
      rocketGoal: {
        target: Number(economy.getConfig().roomGoalThreshold) || 400000,
        current: 0,
        contributors: {},
        metAt: null,
      },
      isActive: true,
      seats: store.buildSeats(chairCount, hostId, hostName),
      createdAt: new Date().toISOString(),
    };
    const rooms = store.getRooms();
    rooms.unshift(room);
    store.saveRooms(rooms);
    res.json({ room });
  });

  app.post('/api/rooms/:id/join', (req, res) => {
    const { userId, userName } = req.body;
    const rooms = store.getRooms();
    const idx = rooms.findIndex((r) => r.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Sala não encontrada' });
    const room = rooms[idx];
    if (room.bannedUsers.includes(userId)) {
      return res.status(403).json({ error: 'Você foi banido desta sala' });
    }
    if (!room.participants.includes(userId)) {
      room.participants.push(userId);
      room.currentUsers = room.participants.length;
    }
    rooms[idx] = room;
    store.saveRooms(rooms);
    res.json({ room });
  });

  app.post('/api/rooms/:id/leave', (req, res) => {
    const { userId } = req.body;
    const rooms = store.getRooms();
    const idx = rooms.findIndex((r) => r.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Sala não encontrada' });
    const room = rooms[idx];
    room.participants = room.participants.filter((p) => p !== userId);
    room.seats = room.seats.map((s) =>
      s.userId === userId ? { ...s, userId: null, userName: null, role: 'participant', isMuted: false } : s
    );
    room.currentUsers = room.participants.length;
    rooms[idx] = room;
    store.saveRooms(rooms);
    res.json({ room });
  });

  app.post('/api/rooms/:id/seats/:seatIndex/take', (req, res) => {
    const { userId, userName } = req.body;
    const seatIndex = parseInt(req.params.seatIndex, 10);
    const rooms = store.getRooms();
    const idx = rooms.findIndex((r) => r.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Sala não encontrada' });
    const room = rooms[idx];
    if (!roles.canTakeSeat(room, seatIndex, userId)) {
      return res.status(403).json({ error: 'Cadeira indisponível' });
    }
    room.seats = room.seats.map((s) => {
      if (s.userId === userId) return { ...s, userId: null, userName: null };
      return s;
    });
    room.seats[seatIndex] = {
      ...room.seats[seatIndex],
      userId,
      userName,
      role: userId === room.hostId ? 'owner' : 'participant',
    };
    if (!room.participants.includes(userId)) {
      room.participants.push(userId);
      room.currentUsers = room.participants.length;
    }
    rooms[idx] = room;
    store.saveRooms(rooms);
    res.json({ room, seat: room.seats[seatIndex] });
  });

  app.post('/api/rooms/:id/seats/:seatIndex/mute', (req, res) => {
    const { actorId, muted } = req.body;
    const seatIndex = parseInt(req.params.seatIndex, 10);
    const rooms = store.getRooms();
    const idx = rooms.findIndex((r) => r.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Sala não encontrada' });
    const room = rooms[idx];
    const actor = store.findUser(actorId);
    if (!roles.canModerateRoom(actor, room)) {
      return res.status(403).json({ error: 'Sem permissão' });
    }
    room.seats[seatIndex].isMuted = !!muted;
    rooms[idx] = room;
    store.saveRooms(rooms);
    res.json({ seat: room.seats[seatIndex] });
  });

  app.post('/api/rooms/:id/seats/:seatIndex/lock', (req, res) => {
    const { actorId, locked } = req.body;
    const seatIndex = parseInt(req.params.seatIndex, 10);
    const rooms = store.getRooms();
    const idx = rooms.findIndex((r) => r.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Sala não encontrada' });
    const room = rooms[idx];
    const actor = store.findUser(actorId);
    if (!roles.canModerateRoom(actor, room)) {
      return res.status(403).json({ error: 'Sem permissão' });
    }
    room.seats[seatIndex].isLocked = !!locked;
    rooms[idx] = room;
    store.saveRooms(rooms);
    res.json({ room, seat: room.seats[seatIndex] });
  });

  app.post('/api/rooms/:id/ban', (req, res) => {
    const { actorId, targetUserId } = req.body;
    const rooms = store.getRooms();
    const idx = rooms.findIndex((r) => r.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Sala não encontrada' });
    const room = rooms[idx];
    const actor = store.findUser(actorId);
    if (!roles.canModerateRoom(actor, room)) {
      return res.status(403).json({ error: 'Sem permissão' });
    }
    if (!room.bannedUsers.includes(targetUserId)) room.bannedUsers.push(targetUserId);
    room.participants = room.participants.filter((p) => p !== targetUserId);
    room.seats = room.seats.map((s) =>
      s.userId === targetUserId ? { ...s, userId: null, userName: null } : s
    );
    room.currentUsers = room.participants.length;
    rooms[idx] = room;
    store.saveRooms(rooms);
    res.json({ room });
  });

  // ── Gifts ──
  app.get('/api/gifts', (_req, res) => {
    res.json({ gifts: APP_GIFT_CATALOG });
  });

  app.post('/api/gifts/send', (req, res) => {
    const { senderId, recipientId, giftId, roomId } = req.body;
    const gift = APP_GIFT_CATALOG.find((g) => g.id === giftId);
    if (!gift) return res.status(404).json({ error: 'Presente não encontrado' });

    const analysis = fraud.analyzeTransaction({
      senderId,
      recipientId,
      recentGifts: store.getGiftLog(),
    });
    if (analysis.blocked) {
      return res.status(403).json({ error: 'Presente bloqueado por segurança', analysis });
    }

    const users = store.getUsers();
    const sIdx = users.findIndex((u) => u.id === senderId);
    const rIdx = users.findIndex((u) => u.id === recipientId);
    if (sIdx < 0 || rIdx < 0) return res.status(404).json({ error: 'Usuário não encontrado' });

    try {
      users[sIdx] = economy.applyBalanceChange(users[sIdx], -gift.price);
    } catch (e) {
      return res.status(400).json({ error: 'Saldo insuficiente' });
    }

    const recipientGain = economy.calculateEarning('gift_received', { amount: gift.price });
    users[rIdx] = economy.applyBalanceChange(users[rIdx], recipientGain);
    users[rIdx].points = (users[rIdx].points || 0) + gift.price;
    store.saveUsers(users);

    store.addGiftLog({ from: senderId, to: recipientId, giftId, roomId, amount: gift.price });

    // A meta do foguete é separada do chat. Todo presente elegível enviado na sala
    // contribui para a meta; o ranking usa a contribuição acumulada por pessoa.
    if (roomId) {
      const rooms = store.getRooms();
      const roomIndex = rooms.findIndex((room) => room.id === roomId);
      if (roomIndex >= 0) {
        const room = rooms[roomIndex];
        const target = Number(room.rocketGoal?.target || economy.getConfig().roomGoalThreshold || 400000);
        const goal = room.rocketGoal || { target, current: 0, contributors: {}, metAt: null };
        goal.target = target;
        goal.current = Number(goal.current || 0) + Number(gift.price || 0);
        goal.contributors = goal.contributors || {};
        goal.contributors[senderId] = Number(goal.contributors[senderId] || 0) + Number(gift.price || 0);
        if (!goal.metAt && goal.current >= target) goal.metAt = new Date().toISOString();
        room.rocketGoal = goal;
        rooms[roomIndex] = room;
        store.saveRooms(rooms);
      }
    }

    store.addTransaction({
      id: txId(),
      userId: senderId,
      type: 'gift_sent',
      amount: -gift.price,
      description: `Presente: ${gift.name}`,
      roomId,
      status: 'completed',
      createdAt: new Date().toISOString(),
    });
    store.addTransaction({
      id: txId(),
      userId: recipientId,
      type: 'gift_received',
      amount: recipientGain,
      description: `Recebeu: ${gift.name}`,
      roomId,
      status: 'completed',
      createdAt: new Date().toISOString(),
    });

    res.json({ success: true, gift, recipientGain, senderBalance: users[sIdx].balance });
  });

  // ── Moderation ──
  app.post('/api/moderation/check', (req, res) => {
    const { text, region } = req.body;
    res.json(moderateContent(text, region || 'Global'));
  });

  // ── Admin ──
  app.get('/api/admin/users', requireAdmin, (req, res) => {
    const admin = req.adminUser;
    let users = store.getUsers().map(store.publicUser);
    if (roles.isRegionalAdmin(admin) && !roles.isCentralAdmin(admin)) {
      users = users.filter((u) => u.region === admin.region);
    }
    res.json({ users });
  });

  app.get('/api/admin/regions', requireAdmin, (req, res) => {
    const admin = req.adminUser;
    let stats = roles.REGIONS.filter(r => r !== 'Global').map((region) => {
      const users = store.getUsers().filter((u) => u.region === region);
      const rooms = store.getRooms().filter((r) => r.region === region && r.isActive);
      return { region, users: users.length, rooms: rooms.length };
    });
    if (roles.isRegionalAdmin(admin) && !roles.isCentralAdmin(admin)) {
      stats = stats.filter((s) => s.region === admin.region);
    }
    res.json({ regions: stats });
  });

  app.get('/api/rtc/zego-token', (req, res) => {
    const { userId, roomId } = req.query;
    if (!userId || !roomId) return res.status(400).json({ error: 'userId e roomId obrigatórios' });
    res.json(zego.generateToken04(String(userId), String(roomId)));
  });

  app.post('/api/webhooks/pagbank', (req, res) => {
    const sig = req.headers['x-pagseguro-signature'] || req.headers['x-hub-signature'] || '';
    const raw = req.rawBody || JSON.stringify(req.body);
    if (!pagbank.verifyWebhookSignature(raw, sig)) {
      return res.status(401).json({ error: 'Assinatura inválida' });
    }
    const event = pagbank.parseWebhookEvent(req.body);
    const pending = pagbank.getPending(event.ref);
    if (!pending || !event.paid) {
      return res.json({ received: true, processed: false });
    }
    pagbank.completePending(event.ref, 'completed');
    const users = store.getUsers();
    const idx = users.findIndex((u) => u.id === pending.user_id || u.id === pending.userId);
    if (idx >= 0 && pending.type === 'recharge') {
      const amount = parseFloat(pending.amount);
      users[idx] = economy.applyCoinsAndDiamonds(users[idx], { coins: amount });
      users[idx].totalSpend = (users[idx].totalSpend || 0) + amount;
      store.saveUsers(users);
      store.addTransaction({
        id: txId(),
        userId: users[idx].id,
        type: 'recharge',
        amount,
        description: 'Recarga PIX confirmada (webhook PagBank)',
        status: 'completed',
        createdAt: new Date().toISOString(),
      });
      syncUserLevelsAndVip();
    }
    res.json({ received: true, processed: true });
  });

  app.get('/api/admin/stats', (_req, res) => {
    const users = store.getUsers();
    const rooms = store.getRooms().filter((r) => r.isActive);
    const txs = store.getTransactions();
    const revenue = txs.filter((t) => t.type === 'commission').reduce((s, t) => s + t.amount, 0);
    const rules = economy.getFullRules();
    const cfg = economy.getConfig();
    res.json({
      totalUsers: users.length,
      activeUsers: users.filter((u) => !u.isAdmin).length,
      activeRooms: rooms.length,
      totalRevenue: revenue,
      monthlyRevenue: revenue,
      platformSplit: `${cfg.platformSplit * 100}%`,
      distributionSplit: `${cfg.userSplit * 100}%`,
      economy: rules.summary,
      levelCount: rules.levelTable.length,
      vipTiers: rules.vipTiers.length,
    });
  });
}

module.exports = { mountApiRoutes };

