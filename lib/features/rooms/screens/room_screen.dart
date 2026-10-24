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
    this.chairCount = 12,
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
        : (widget.roomName.isNotEmpty ? widget.roomName : 'Audio Room Live');
    final idText = widget.roomId ?? room?.id ?? 'local';
    final owner = (room != null && room.hostName.isNotEmpty) ? room.hostName : '-';
    final seatCount = (room?.seats.length ?? widget.chairCount).clamp(1, 30).toInt();
    final online = room?.currentUsers ?? widget.spectatorCount;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Topo: vidro translúcido.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          child: Row(
                            children: [
                              _CircleAction(
                                icon: Icons.arrow_back_rounded,
                                size: 40,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: $idText · Owner: $owner',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0x33000000),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x6678F0C4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF78F0C4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$online online',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CircleAction(
                                icon: Icons.more_horiz_rounded,
                                size: 40,
                                onTap: _showRoomMenu,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Grade de cadeiras (3 colunas).
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                      itemCount: seatCount,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final seat = (room != null && index < room.seats.length)
                            ? room.seats[index]
                            : null;
                        final isMe = seat?.userId != null && seat!.userId == me?.id;
                        return _SeatTile(
                          index: index,
                          seat: seat,
                          isMe: isMe,
                          micOn: _micOn,
                          onTap: () {
                            final taken = seat?.userId != null && seat!.userId!.isNotEmpty;
                            if (taken) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMe ? 'Seu lugar na sala' : (seat.userName ?? 'Usuário'),
                                  ),
                                ),
                              );
                            } else if (seat?.isLocked ?? false) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cadeira bloqueada')),
                              );
                            } else {
                              _takeSeat(index);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  if (_showChat && _messages.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 104),
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x99000000),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _messages
                            .skip(_messages.length > 4 ? _messages.length - 4 : 0)
                            .map(
                              (m) => Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${m.sender}: ',
                                      style: const TextStyle(
                                        color: _neonA,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(text: m.text),
                                  ],
                                ),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  // Barra inferior flutuante com blur.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0x2EFFFFFF)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  onSubmitted: (_) => _sendMessage(),
                                  textInputAction: TextInputAction.send,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Say hi to everyone...',
                                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                    border: InputBorder.none,
                                    isDense: true,
                                    suffixIcon: IconButton(
                                      onPressed: _sendMessage,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      icon: const Icon(Icons.send_rounded, color: _neonA, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _CircleAction(
                                icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                                size: 44,
                                fill: _micOn ? const Color(0xFF1FD6A0) : const Color(0x33FFFFFF),
                                iconColor: _micOn ? const Color(0xFF07201A) : Colors.white,
                                onTap: () => setState(() => _micOn = !_micOn),
                              ),
                              const SizedBox(width: 8),
                              _CircleAction(
                                icon: Icons.call_end_rounded,
                                size: 44,
                                fill: const Color(0xFFE53935),
                                onTap: _leaveRoom,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _openGifts,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_neonA, _neonB],
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Color(0x9900F2FE), blurRadius: 16, spreadRadius: 1),
                                      BoxShadow(color: Color(0x776807BA), blurRadius: 22, spreadRadius: 2),
                                    ],
                                  ),
                                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Botão do foguete: acima da barra, canto inferior direito.
            Positioned(
              right: 18,
              bottom: bottomInset + 96,
              child: GestureDetector(
                onTap: () => _launchRocket(me?.name ?? '', me?.photoUrl),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE7A1), Color(0xFFFF8A3D)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x88FFB300), blurRadius: 16, spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF111225), size: 28),
                ),
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
                              border: Border.all(color: _neonA, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Color(0x8800F2FE), blurRadius: 30, spreadRadius: 2),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                _entryAsset!,
                                width: 240,
                                height: 240,
                                fit: BoxFit.cover,
                                cacheWidth: 600,
                                errorBuilder: (context, error, stack) => const SizedBox(
                                  width: 240,
                                  height: 240,
                                  child: Icon(Icons.workspace_premium_rounded, color: _neonA, size: 110),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '$_entryName entrou na sala',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                            ),
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
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _seatBorder, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                locked ? Icons.lock_outline_rounded : Icons.add_rounded,
                color: _seatIcon,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text('${index + 1}', style: const TextStyle(color: _seatIcon, fontSize: 11)),
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
            width: 68,
            height: 68,
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
          const SizedBox(height: 7),
          Text(
            isMe ? 'Você' : (s.userName ?? 'Usuário'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Icon(
            muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            size: 15,
            color: muted ? Colors.white54 : const Color(0xFF78F0C4),
          ),
        ],
      ),
    );
  }
}
