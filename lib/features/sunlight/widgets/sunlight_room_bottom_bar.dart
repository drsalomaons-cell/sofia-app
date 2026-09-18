import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/sunlight/theme/sunlight_room_layout.dart';

/// Barra inferior de sala — padrão Sunlight Live.
class SunlightRoomBottomBar extends StatelessWidget {
  final bool micActive;
  final bool chatOpen;
  final VoidCallback onMic;
  final VoidCallback onChat;
  final VoidCallback onGift;
  final VoidCallback onLeave;

  const SunlightRoomBottomBar({
    super.key,
    required this.micActive,
    required this.chatOpen,
    required this.onMic,
    required this.onChat,
    required this.onGift,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final scale = SunlightRoomLayout.compactScale(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10 * scale, 8 * scale, 10 * scale, 10 * scale),
      decoration: BoxDecoration(
        color: AppTheme.preto.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: AppTheme.dourado.withValues(alpha: 0.25))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(Icons.chat_bubble_outline, 'Chat', chatOpen ? AppTheme.dourado : AppTheme.branco, scale, onChat),
          _btn(micActive ? Icons.mic : Icons.mic_off, micActive ? 'Ao vivo' : 'Mic', micActive ? AppTheme.dourado : AppTheme.cinzaMedio, scale, onMic),
          _btn(Icons.card_giftcard_outlined, 'Presente', AppTheme.lilas, scale, onGift),
          _btn(Icons.emoji_events_outlined, 'Ranking', AppTheme.amarelo, scale, () {}),
          _btn(Icons.exit_to_app, 'Sair', AppTheme.vermelho, scale, onLeave),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color color, double scale, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22 * scale),
            SizedBox(height: 2 * scale),
            Text(label, style: TextStyle(color: color, fontSize: 9 * scale)),
          ],
        ),
      ),
    );
  }
}
