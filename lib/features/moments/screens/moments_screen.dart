import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _momentCard('Maria', 'Entrei na sala Festa VIP 🎉', '2 min'),
        _momentCard('Host Alpha', 'Meta da sala atingida! +2% bônus', '15 min'),
        _momentCard('Sistema', 'Evento de abertura ativo — 72h', '1 h'),
      ],
    );
  }

  Widget _momentCard(String author, String text, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.roxo.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: AppTheme.dourado, child: Text(author[0], style: const TextStyle(color: AppTheme.preto, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dourado)),
                  const SizedBox(height: 4),
                  Text(text),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.cinzaMedio)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
