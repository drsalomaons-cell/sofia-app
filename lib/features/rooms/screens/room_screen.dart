import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/sunlight/widgets/rocket_launch_overlay.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_gift_panel.dart';
import 'package:sofia/models/room_model.dart';
import 'package:sofia/models/seat_model.dart';
import 'package:sofia/services/room_service.dart';
import 'package:sofia/services/socket_service.dart';

// Paleta extraída do layout Stitch (HTML/Tailwind).
const _bgTop = Color(0xFF111225);
const _bgBottom = Color(0xFF1D1E32);
const _seatBorder = Color(0xFF3A494B);
const _seatIcon = Color(0xFF7A8F91);
const _neonA = Color(0xFF00F2FE);
const _neonB = Color(0xFF6807BA);

class RoomScreen extends StatefulWidget {
  final String? roomId;
  final String roomName;
  final String roomTheme;
  final int spectatorCount;
  final int chairCount;

  const RoomScreen({
    super.key,
    this.roomId,
    required this.roomName,
    required this.roomTheme,
    this.spectatorCount = 12,
    this.chairCount = 8,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatLine> _messages = <_ChatLine>[];
  final Set<String> _messageIds = <String>{};
  SocketService? _socket;
  String? _userId;
  RoomModel? _room;
  bool _micOn = false;
  bool _showChat = false;

  bool _showRocket = false;
  int _rocketSeq = 0;
  String _rocketSender = '';
  String? _rocketAvatar;

  String? _entryAsset;
  String _entryName = '';
  Timer? _entryTimer;
  static const _entries = ['leao', 'dragao', 'fenix', 'merlin', 'rei', 'carro'];

  String _lastSentText = '';
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    final roomId = widget.roomId;
    if (roomId != null && _userId != null) {
      _socket?.leaveRoom(roomId, _userId!);
    }
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _userId = user.id;
    _showEntry(user.name, self: true);
    final roomId = widget.roomId;
    if (roomId == null) return;

    final socket = context.read<SocketService>();
    _socket = socket;
    socket.joinRoom(roomId, user.id, user.name);
    socket.onChat((data) {
      if (!mounted) return;
      final id = data['id']?.toString() ?? '';
      // Dedupe por id: a mesma mensagem nunca entra duas vezes.
      if (id.isNotEmpty && !_messageIds.add(id)) return;
      final text = data['text']?.toString() ?? '';
      if (text.isEmpty) return;
      setState(() {
        _messages.add(_ChatLine(data['sender']?.toString() ?? 'Usuário', text));
        _showChat = true;
      });
    });
    socket.onUserJoined((data) {
      if (!mounted) return;
      final name = data['userName']?.toString() ?? '';
      if (name.isNotEmpty) _showEntry(name);
    });
    socket.onRoomState((data) {
      final raw = data['room'];
      if (!mounted || raw is! Map) return;
      setState(() => _room = RoomModel.fromJson(Map<String, dynamic>.from(raw)));
    });
    socket.onGift((data) {
      if (!mounted) return;
      // O próprio remetente já viu o efeito localmente.
      if (data['senderId']?.toString() == _userId) return;
      if (data['giftId']?.toString() == 'rocket') {
        _launchRocket(
          data['senderName']?.toString() ?? '',
          data['senderPhotoUrl']?.toString(),
        );
      }
    });

    try {
      final room = await RoomService().getRoomById(roomId);
      if (mounted && room != null) setState(() => _room = room);
    } catch (_) {}
  }

  void _launchRocket(String name, String? photoUrl) {
    if (!mounted) return;
    setState(() {
      _rocketSender = name;
      _rocketAvatar = photoUrl;
      _rocketSeq++;
      _showRocket = true;
    });
  }

  void _showEntry(String name, {bool self = false}) {
    final asset = self ? 'leao' : _entries[name.hashCode.abs() % _entries.length];
    _entryTimer?.cancel();
    setState(() {
      _entryAsset = 'assets/images/entradas/$asset.png';
      _entryName = name;
    });
    _entryTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _entryAsset = null);
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    // Trava contra disparo duplo (teclado + botão) do mesmo texto.
    final now = DateTime.now();
    if (text == _lastSentText && now.difference(_lastSentAt).inMilliseconds < 700) {
      return;
    }
    _lastSentText = text;
    _lastSentAt = now;

    final user = context.read<AuthProvider>().user;
    final id = '${user?.id ?? 'local'}-${now.microsecondsSinceEpoch}';
    final sender = user?.name ?? 'Você';
    _messageIds.add(id); // o eco do servidor (se houver) é ignorado por este id
    setState(() {
      _messages.add(_ChatLine(sender, text));
      _chatController.clear();
      _showChat = true;
    });
    final roomId = widget.roomId;
    if (roomId != null) {
      _socket?.sendChat(roomId, {
        'id': id,
        'text': text,
        'sender': sender,
        'isSystem': false,
      });
    }
  }

  Future<void> _takeSeat(int index) async {
    final user = context.read<AuthProvider>().user;
    final roomId = widget.roomId;
    if (user == null || roomId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await RoomService().takeSeat(roomId, index, user.id, user.name);
      if (mounted && updated != null) setState(() => _room = updated);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveRoom() async {
    final user = context.read<AuthProvider>().user;
    final roomId = widget.roomId;
    final nav = Navigator.of(context);
    if (user != null && roomId != null) {
      try {
        await RoomService().leaveRoom(roomId, user.id);
      } catch (_) {}
    }
    if (mounted) nav.maybePop();
  }

  Future<void> _openGifts() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AuthProvider>().user;
    final roomId = widget.roomId;
    if (user == null || roomId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Entre com sua conta em uma sala para enviar presentes.')),
      );
      return;
    }
    var room = _room;
    if (room == null) {
      try {
        room = await RoomService().getRoomById(roomId);
      } catch (_) {}
      if (!mounted) return;
    }
    String? recipientId;
    if (room != null) {
      final candidates = <String?>[
        ...room.seats.map((s) => s.userId),
        room.hostId,
        ...room.participants,
      ];
      for (final id in candidates) {
        if (id != null && id.isNotEmpty && id != user.id) {
          recipientId = id;
          break;
        }
      }
    }
    // TESTE TEMPORARIO: se nao houver outro participante, envia para si mesmo.
    recipientId ??= user.id;
    showSofiaPremiumGiftPanel(
      context,
      roomId: roomId,
      roomName: room?.name ?? widget.roomName,
      isHost: room?.hostId == user.id,
      participantCount: room?.currentUsers ?? widget.spectatorCount,
      recipientId: recipientId,
      onGiftSent: (gift, combo) {
        if (gift.id == 'rocket') _launchRocket(user.name, user.photoUrl);
      },
    );
  }

  void _showRoomMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgBottom,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: _neonA),
              title: const Text('Informações da sala', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'ID: ${widget.roomId ?? 'local'}',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white70),
              title: const Text('Fechar menu', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().user;
    final room = _room;
    final title = (room != null && room.name.isNotEmpty)
        ? room.name
        : (widget.roomName.isNotEmpty ? widget.roomName : 'Palácio de Voz');
    SeatModel? hostSeat;
    if (room != null) {
      for (final candidate in room.seats) {
        if (candidate.userId == room.hostId) {
          hostSeat = candidate;
          break;
        }
      }
    }
    final hostPhoto = hostSeat?.photoUrl ?? (room?.hostId == me?.id ? me?.photoUrl : null);
    final hostName = room?.hostName.isNotEmpty == true ? room!.hostName : 'Anfitrião';
    final online = room?.currentUsers ?? widget.spectatorCount;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final seatPanelHeight = screenHeight < 760 ? 174.0 : 190.0;

    Widget pill(String label, Color color, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: color, size: 11),
          if (icon != null) const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    Widget filter(String label, {bool selected = false, IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF00F5D4) : const Color(0x332D2140),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 10, color: selected ? const Color(0xFF151020) : const Color(0xFFFFD76A)),
          if (icon != null) const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF151020) : Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF10091B),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10091B), Color(0xFF21102F), Color(0xFF130D22)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xFF38234C),
                          backgroundImage: hostPhoto != null && hostPhoto.isNotEmpty ? NetworkImage(hostPhoto) : null,
                          child: hostPhoto == null || hostPhoto.isEmpty
                              ? const Icon(Icons.person_rounded, color: Color(0xFF00F5D4))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(hostName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                              const Text('HOST  •  AO VIVO',
                                style: TextStyle(color: Color(0xFFFFD76A), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                            ],
                          ),
                        ),
                        _CircleAction(
                          icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                          size: 34, fill: const Color(0x3325D9D0), iconColor: const Color(0xFF00F5D4),
                          onTap: () => setState(() => _micOn = !_micOn),
                        ),
                        const SizedBox(width: 6),
                        _CircleAction(
                          icon: Icons.keyboard_arrow_down_rounded, size: 34,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Minimização flutuante ainda precisa ser ligada à navegação.')),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _CircleAction(
                          icon: Icons.close_rounded, size: 34,
                          fill: const Color(0x33FF526D), iconColor: const Color(0xFFFF8295),
                          onTap: _leaveRoom,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: pill('LOUNGE DE VOZ (8 ASSENTOS)', const Color(0xFFB49BFF))),
                        const SizedBox(width: 5),
                        Expanded(flex: 3, child: pill('$online online', const Color(0xFF00F5D4), icon: Icons.remove_red_eye_rounded)),
                        const SizedBox(width: 5),
                        Expanded(flex: 3, child: pill('TOP 1 DIÁRIO', const Color(0xFFFFD76A), icon: Icons.emoji_events_rounded)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 7, 14, 2),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD76A), size: 15),
                        const SizedBox(width: 6),
                        const Text('Patronos', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 11, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text((room?.earnings.toStringAsFixed(0) ?? '0') + ' diamantes',
                          style: const TextStyle(color: Color(0xFF00F5D4), fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 7),
                    child: Column(
                      children: [
                        Container(
                          width: 82, height: 82, padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00F5D4), width: 2),
                            gradient: const LinearGradient(colors: [Color(0xFF00F5D4), Color(0xFF7D4DFF), Color(0xFFFFD76A)]),
                            boxShadow: const [BoxShadow(color: Color(0x7700F5D4), blurRadius: 18, spreadRadius: 1)],
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF28163A),
                            backgroundImage: hostPhoto != null && hostPhoto.isNotEmpty ? NetworkImage(hostPhoto) : null,
                            child: hostPhoto == null || hostPhoto.isEmpty
                                ? const Icon(Icons.person_rounded, color: Colors.white, size: 36)
                                : null,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFFFD76A), borderRadius: BorderRadius.circular(12)),
                          child: const Text('FALANDO', style: TextStyle(color: Color(0xFF27152C), fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 3),
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                        Text(hostName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF00F5D4), fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Container(
                    height: seatPanelHeight,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
                    padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                    decoration: BoxDecoration(
                      color: const Color(0xAA281A3A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x447E68B8)),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: 8,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, crossAxisSpacing: 3, mainAxisSpacing: 2, mainAxisExtent: 82,
                      ),
                      itemBuilder: (context, index) {
                        final seat = (room != null && index < room.seats.length) ? room.seats[index] : null;
                        final isMe = seat?.userId != null && seat!.userId == me?.id;
                        return _SeatTile(
                          index: index, seat: seat, isMe: isMe, micOn: _micOn,
                          onTap: () {
                            final taken = seat?.userId != null && seat!.userId!.isNotEmpty;
                            if (taken) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isMe ? 'Seu lugar na sala' : (seat.userName ?? 'Usuário'))),
                              );
                            } else if (seat?.isLocked ?? false) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadeira bloqueada')));
                            } else if (seat?.role == 'reserved') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadeira reservada')));
                            } else {
                              _takeSeat(index);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 10, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
                              decoration: BoxDecoration(color: const Color(0x33120B20), borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      filter('Todas', selected: true),
                                      const SizedBox(width: 5),
                                      filter('Chat'),
                                      const SizedBox(width: 5),
                                      filter('Diamantes', icon: Icons.diamond_rounded),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Expanded(
                                    child: _messages.isEmpty
                                        ? const Align(
                                            alignment: Alignment.topLeft,
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text('Aguardando mensagens da sala...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                            ),
                                          )
                                        : ListView.builder(
                                            reverse: true,
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              final message = _messages[_messages.length - 1 - index];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 5),
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                                decoration: BoxDecoration(color: const Color(0x662D1C43), borderRadius: BorderRadius.circular(12)),
                                                child: Text.rich(
                                                  TextSpan(children: [
                                                    TextSpan(text: message.sender + ': ',
                                                      style: const TextStyle(color: Color(0xFF00F5D4), fontWeight: FontWeight.w900)),
                                                    TextSpan(text: message.text),
                                                  ]),
                                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          SizedBox(
                            width: 48,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _CircleAction(
                                  icon: Icons.sports_kabaddi_rounded, size: 42,
                                  fill: const Color(0xFF251B45), iconColor: const Color(0xFF00F5D4),
                                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PK: integrar ao módulo de batalha existente.')),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                _CircleAction(
                                  icon: Icons.card_giftcard_rounded, size: 42,
                                  fill: const Color(0xFFFFD76A), iconColor: const Color(0xFF2A1733),
                                  onTap: _openGifts,
                                ),
                                const SizedBox(height: 7),
                                _CircleAction(
                                  icon: Icons.sports_esports_rounded, size: 42,
                                  fill: const Color(0xFF251B45), iconColor: const Color(0xFFB79CFF),
                                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Jogos: integrar ao módulo de jogos existente.')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 3, 12, 8 + bottomInset * 0.15),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
                      decoration: BoxDecoration(
                        color: const Color(0xCC302344),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0x447F6AAE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              onSubmitted: (_) => _sendMessage(),
                              textInputAction: TextInputAction.send,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Dizer no lounge...',
                                hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded, color: Color(0xFF00F5D4), size: 19), visualDensity: VisualDensity.compact),
                          _CircleAction(
                            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded, size: 38,
                            fill: _micOn ? const Color(0xFF00D9B8) : const Color(0x337F6AAE),
                            iconColor: _micOn ? const Color(0xFF10202A) : Colors.white,
                            onTap: () => setState(() => _micOn = !_micOn),
                          ),
                          const SizedBox(width: 5),
                          _CircleAction(icon: Icons.call_end_rounded, size: 38, fill: const Color(0xFFE84A68), onTap: _leaveRoom),
                          const SizedBox(width: 5),
                          _CircleAction(icon: Icons.card_giftcard_rounded, size: 42, fill: const Color(0xFFFFD76A), iconColor: const Color(0xFF2A1733), onTap: _openGifts),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_entryAsset != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: const Color(0x99050713),
                    alignment: Alignment.center,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_entryAsset),
                      tween: Tween<double>(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) => Opacity(
                        opacity: scale.clamp(0.0, 1.0),
                        child: Transform.scale(scale: scale, child: child),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFF00F5D4), width: 2),
                              boxShadow: const [BoxShadow(color: Color(0x8800F5D4), blurRadius: 30, spreadRadius: 2)],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                _entryAsset!, width: 240, height: 240, fit: BoxFit.cover, cacheWidth: 600,
                                errorBuilder: (context, error, stack) => const SizedBox(
                                  width: 240, height: 240,
                                  child: Icon(Icons.workspace_premium_rounded, color: Color(0xFF00F5D4), size: 110),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _entryName + ' entrou na sala',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black87, blurRadius: 8)]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showRocket)
              RocketLaunchOverlay(
                key: ValueKey(_rocketSeq),
                level: 1,
                senderName: _rocketSender,
                avatarUrl: _rocketAvatar,
                onFinished: () {
                  if (mounted) setState(() => _showRocket = false);
                },
              ),
          ],
        ),
      ),
    );
  }

class _ChatLine {
  final String sender;
  final String text;
  const _ChatLine(this.sender, this.text);
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color fill;
  final Color iconColor;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.fill = const Color(0x33FFFFFF),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: fill,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    ),
  );
}

class _SeatTile extends StatelessWidget {
  final int index;
  final SeatModel? seat;
  final bool isMe;
  final bool micOn;
  final VoidCallback onTap;

  const _SeatTile({
    required this.index,
    required this.seat,
    required this.isMe,
    required this.micOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = seat;
    final taken = s != null && s.userId != null && s.userId!.isNotEmpty;
    if (!taken) {
      final locked = s?.isLocked ?? false;
      final reserved = s?.role == 'reserved';
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: reserved ? const Color(0xFFFFD76A) : _seatBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                locked
                    ? Icons.lock_outline_rounded
                    : reserved
                        ? Icons.event_seat_rounded
                        : Icons.add_rounded,
                color: reserved ? const Color(0xFFFFD76A) : _seatIcon,
                size: 25,
              ),
              const SizedBox(height: 2),
              Text(
                reserved ? 'Reservada' : '${index + 1}',
                style: TextStyle(
                  color: reserved ? const Color(0xFFFFD76A) : _seatIcon,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final muted = isMe ? !micOn : s.isMuted;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_neonA, _neonB],
              ),
              boxShadow: [BoxShadow(color: Color(0x6600F2FE), blurRadius: 14, spreadRadius: 1)],
            ),
            child: SenderAvatar(url: s.photoUrl, name: s.userName ?? ''),
          ),
          const SizedBox(height: 3),
          Text(
            isMe ? 'Você' : (s.userName ?? 'Usuário'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 1),
          Icon(
            muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            size: 12,
            color: muted ? Colors.white54 : const Color(0xFF78F0C4),
          ),
        ],
      ),
    );
  }
}
