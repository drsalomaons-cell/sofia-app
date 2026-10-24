import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/models/user_model.dart';

/// Modal informativo sobre o Charme e Carisma do usuário no ecossistema SOFIA.
class CharmDialog extends StatelessWidget {
  final UserModel? user;

  const CharmDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, UserModel? user) {
    return showDialog<void>(
      context: context,
      builder: (_) => CharmDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charmPoints = user?.charmLevel ?? user?.points ?? 0;
    final level = (charmPoints ~/ 100) + 1;

    return Dialog(
      backgroundColor: const Color(0xFF141733),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFF76C8), Color(0xFF550838)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF76C8).withValues(alpha: 0.4),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'NÍVEL DE CHARME',
              style: TextStyle(
                color: Color(0xFFFF76C8),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nível $level',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$charmPoints pontos acumulados',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.cinzaMedio,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como funciona o Charme?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Seu charme cresce a cada presente recebido em salas de áudio e lives.\n'
                    '• Quanto maior seu nível de charme, mais destaque você tem nos rankings globais.\n'
                    '• Níveis avançados desbloqueiam títulos exclusivos de nobreza e molduras raras.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.cinzaMedio,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF76C8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
