import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';

class RoomChatPanel extends StatefulWidget {
  final List<RoomChatMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final double? height;

  const RoomChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    this.height,
  });

  @override
  State<RoomChatPanel> createState() => _RoomChatPanelState();
}

class _RoomChatPanelState extends State<RoomChatPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant RoomChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? (MediaQuery.sizeOf(context).height * 0.26).clamp(130.0, 170.0);

    return Container(
      height: h,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: BoxDecoration(
        color: AppTheme.preto.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dourado.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.roxo.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.dourado),
                const SizedBox(width: 6),
                Text('Chat (${widget.messages.length})', style: const TextStyle(fontSize: 12, color: AppTheme.dourado, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: widget.messages.length,
              itemBuilder: (_, i) {
                final m = widget.messages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: AppTheme.branco, height: 1.25),
                      children: [
                        TextSpan(
                          text: '${m.sender}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: m.isSystem ? AppTheme.amarelo : AppTheme.lilas,
                          ),
                        ),
                        TextSpan(text: m.text),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(color: AppTheme.branco, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Mensagem...',
                      hintStyle: TextStyle(color: AppTheme.cinzaMedio.withValues(alpha: 0.85), fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.roxo.withValues(alpha: 0.55),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: widget.onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.dourado,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.send_rounded, color: AppTheme.preto, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomChatMessage {
  final String text;
  final String sender;
  final bool isSystem;

  RoomChatMessage({required this.text, required this.sender, this.isSystem = false});
}
