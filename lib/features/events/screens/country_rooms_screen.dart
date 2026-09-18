import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/routes/app_routes.dart';

class CountryRoomsScreen extends StatelessWidget {
  final String country;

  const CountryRoomsScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Salas — $country')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.meeting_room, color: AppTheme.roxo),
              title: Text('Sala $country ${index + 1}'),
              subtitle: Text('${8 + index * 2} online'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.room,
                arguments: {
                  'name': 'Sala $country ${index + 1}',
                  'theme': country,
                  'spectators': '${8 + index * 2}',
                  'chairs': '12',
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
