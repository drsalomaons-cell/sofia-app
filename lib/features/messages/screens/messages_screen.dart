import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';

class MessagesScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const MessagesScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final chats = [
      ('Sistema SOFIA', 'Bem-vindo! Sua conta está ativa.', true),
      ('Suporte', 'Precisa de ajuda? Estamos online.', false),
      ('Eventos', 'Nova sala Festa VIP aberta!', false),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chats.length,
      itemBuilder: (context, i) {
        final c = chats[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: c.$3 ? AppTheme.dourado : AppTheme.roxo,
            child: Icon(c.$3 ? Icons.notifications : Icons.chat, color: AppTheme.branco, size: 20),
          ),
          title: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(c.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: c.$3 ? const Icon(Icons.circle, size: 10, color: AppTheme.dourado) : null,
          onTap: () {},
        );
      },
    );
  }
}
