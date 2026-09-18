import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/routes/app_routes.dart';

class EventDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final int participants;

  const EventDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                gradient: AppTheme.gradienteRoxoDourado,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.event, size: 64, color: AppTheme.branco),
            ),
            const SizedBox(height: 16),
            Text(date, style: const TextStyle(color: AppTheme.cinzaMedio)),
            const SizedBox(height: 8),
            Text('$participants participantes'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.room,
                  arguments: {
                    'name': title,
                    'theme': 'Evento',
                    'spectators': '$participants',
                    'chairs': '12',
                  },
                ),
                child: const Text('ENTRAR NO EVENTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
