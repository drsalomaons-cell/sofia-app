import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/routes/app_routes.dart';

class EventsTabScreen extends StatelessWidget {
  final bool embedded;

  const EventsTabScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppTheme.dourado,
            labelColor: AppTheme.dourado,
            unselectedLabelColor: AppTheme.cinzaMedio,
            tabs: [
              Tab(text: 'Populares'),
              Tab(text: 'Por País'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildPopularEvents(context), _buildByCountry(context)],
            ),
          ),
        ],
      ),
    );

    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Eventos')), body: body);
  }

  Widget _buildPopularEvents(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: {
            'title': 'Festa ${index + 1}',
            'date': '25/12/2024 - 22:00',
            'participants': 50 + index * 10,
          }),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.roxo.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradienteRoxoDourado,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event, size: 40, color: AppTheme.branco),
                  ),
                  const SizedBox(height: 10),
                  Text('Festa ${index + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${50 + index * 10} participantes', style: const TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildByCountry(BuildContext context) {
    const countries = ['🇧🇷 Brasil', '🇺🇸 EUA', '🇲🇽 México', '🇳🇬 Nigéria', '🇮🇳 Índia', '🇪🇸 Espanha'];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final parts = countries[index].split(' ');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(parts[0], style: const TextStyle(fontSize: 28)),
            title: Text(parts.sublist(1).join(' ')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.countryRooms, arguments: {'country': parts.sublist(1).join(' ')}),
          ),
        );
      },
    );
  }
}
