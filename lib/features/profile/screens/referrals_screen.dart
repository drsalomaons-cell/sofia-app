import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';

class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final referrals = context.watch<AuthProvider>().user?.referrals ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Indicados')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.gradienteRoxoDourado,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total de indicados', style: TextStyle(color: AppTheme.branco)),
                  const SizedBox(height: 8),
                  Text(
                    '$referrals',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.branco,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Compartilhe seu código SOFIA e ganhe recompensas.'),
          ],
        ),
      ),
    );
  }
}
