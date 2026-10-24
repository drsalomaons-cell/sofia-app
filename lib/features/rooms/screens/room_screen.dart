import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/services/room_service.dart';
import 'package:sofia/features/sunlight/widgets/rocket_launch_overlay.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_gift_panel.dart';

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
  final List<String> _messages = <String>[];
  bool _micOn = false;
  bool _showChat = false;
  bool _showRocket = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _chatController.clear();
      _showChat = true;
    });
  }

  Future<void> _openGifts() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AuthProvider>().user;
    final roomId = widget.roomId;
    if (user == null || roomId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Entre com sua conta em uma sala para enviar presentes.')));
      return;
    }
    final room = await RoomService().getRoomById(roomId);
    if (!mounted) return;
    String? recipientId;
    if (room != null) {
      final candidates = <String?>[room.hostId, ...room.participants.cast<String?>()];
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
      roomName: widget.roomName,
      isHost: room?.hostId == user.id,
      participantCount: widget.spectatorCount,
      recipientId: recipientId,
      onGiftSent: (gift, combo) {
        if (gift.id == 'rocket' && mounted) setState(() => _showRocket = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.chairCount.clamp(1, 30);
    return Scaffold(
      backgroundColor: const Color(0xFF080A17),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo premium em Flutter puro (sem imagem).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2A1458), Color(0xFF141A3D), Color(0xFF070918)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.55),
                radius: 0.95,
                colors: [Color(0x3352D6F5), Color(0x00000000)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Camada 3: cabeçalho.
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roomName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'SALA • ${widget.roomTheme} • ${widget.spectatorCount} online',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFB8DDE7),
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: const Color(0xFF11182A),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.info_outline, color: Color(0xFFFFD76A)),
                                  title: const Text('Informações da sala', style: TextStyle(color: Colors.white)),
                                  subtitle: Text('ID: ${widget.roomId ?? 'local'}', style: const TextStyle(color: Colors.white60)),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close, color: Colors.white70),
                                  title: const Text('Fechar menu', style: TextStyle(color: Colors.white)),
                                  onTap: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Identificação e destaque visual da sala.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xA80A1222),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x66F6D77A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD76A), size: 17),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('SOFIA • SALA PREMIUM', style: TextStyle(color: Color(0xFFFFE7A1), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                      ),
                      Text('${count} lugares', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Camada 2: grade 3x3 dos lugares/avatares.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 9,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final occupied = index == 0;
                        return GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(occupied ? 'Seu lugar na sala' : 'Lugar ${index + 1} selecionado')),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xA6101728),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: occupied ? const Color(0xFFFFD76A) : const Color(0x6688DCE8),
                                width: occupied ? 1.8 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x3300D9F5), blurRadius: 12, spreadRadius: 1),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(5, 8, 5, 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SeatAvatar(occupied: occupied),
                                const SizedBox(height: 7),
                                Text(
                                  occupied ? 'Você' : 'Lugar ${index + 1}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Icon(
                                  occupied && _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                                  size: 15,
                                  color: occupied && _micOn ? const Color(0xFF78F0C4) : Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_showChat)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: const Color(0xCC08101F), borderRadius: BorderRadius.circular(12)),
                    child: ListView(
                      shrinkWrap: true,
                      children: _messages.take(3).map((m) => Text(m, style: const TextStyle(color: Colors.white, fontSize: 12))).toList(),
                    ),
                  ),
                // Camada 4: barra inferior de chat, microfone e presente.
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xE9080D1A),
                    border: Border(top: BorderSide(color: Color(0x55A5EAF2))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showChat = !_showChat),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: const Color(0xFF1A2437), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x668CE9F4))),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, color: Color(0xFF8CE9F4), size: 19),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _chatController,
                                    onSubmitted: (_) => _sendMessage(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    decoration: const InputDecoration(hintText: 'Diga algo...', hintStyle: TextStyle(color: Colors.white54, fontSize: 12), border: InputBorder.none, isDense: true),
                                  ),
                                ),
                                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded, color: Color(0xFFFFD76A), size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 30)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundButton(
                        icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                        active: _micOn,
                        onTap: () => setState(() => _micOn = !_micOn),
                      ),
                      const SizedBox(width: 8),
                      _RoundButton(
                        icon: Icons.card_giftcard_rounded,
                        active: true,
                        onTap: _openGifts,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botão flutuante do foguete (Flutter puro).
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 86,
            child: GestureDetector(
              onTap: () => setState(() => _showRocket = true),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE7A1), Color(0xFFFFB300)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x88FFB300), blurRadius: 16, spreadRadius: 1),
                    BoxShadow(color: Color(0x5531D7FF), blurRadius: 24, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF101629), size: 28),
              ),
            ),
          ),
          if (_showRocket)
            RocketLaunchOverlay(
              level: 1,
              onFinished: () {
                if (mounted) setState(() => _showRocket = false);
              },
            ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _RoundButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => Material(
    color: active ? const Color(0xFFFFD76A) : const Color(0xB8172236),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: active ? const Color(0xFF101629) : Colors.white, size: 21),
      ),
    ),
  );
}

/// Avatar da cadeira: CircleAvatar com anel/moldura desenhado em Flutter puro.
class _SeatAvatar extends StatelessWidget {
  final bool occupied;
  const _SeatAvatar({required this.occupied});

  @override
  Widget build(BuildContext context) {
    final ring = occupied
        ? const [Color(0xFFFFE7A1), Color(0xFFFFB300), Color(0xFFFFE7A1)]
        : const [Color(0xFF8CE9F4), Color(0xFF7B5CFF), Color(0xFF8CE9F4)];
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: ring),
              boxShadow: [BoxShadow(color: ring[1].withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 1)],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(3.5),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF1B2140),
              child: Icon(Icons.person_rounded, color: Colors.white70, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}