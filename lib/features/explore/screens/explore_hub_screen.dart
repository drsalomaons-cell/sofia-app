import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/events/screens/events_tab_screen.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/widgets/sofia_cover_image.dart';

/// Explorar → Salas | Eventos | Rankings
class ExploreHubScreen extends StatelessWidget {
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppTheme.dourado,
            labelColor: AppTheme.dourado,
            unselectedLabelColor: AppTheme.cinzaMedio,
            tabs: [
              Tab(text: 'Salas'),
              Tab(text: 'Eventos'),
              Tab(text: 'Rankings'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RoomsTab(),
                const EventsTabScreen(embedded: true),
                _RankingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RoomProvider>(
        builder: (context, rooms, _) {
          if (rooms.isLoading && rooms.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.dourado));
          }
          final list = rooms.rooms;
          return RefreshIndicator(
            color: AppTheme.dourado,
            onRefresh: rooms.loadActiveRooms,
            child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: list.isEmpty ? 4 : list.length,
            itemBuilder: (context, index) {
              if (list.isEmpty) {
                return Card(
                  color: AppTheme.roxo.withValues(alpha: 0.3),
                  child: const Center(child: Text('Nenhuma sala', style: TextStyle(color: AppTheme.cinzaMedio))),
                );
              }
              final room = list[index];
              return InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.room, arguments: {
                  'id': room.id,
                  'name': room.name,
                  'theme': room.theme,
                  'chairs': '${room.chairs}',
                }),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  color: AppTheme.roxo.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(opacity: 0.35, child: SofiaCoverImage(variant: 'splash', fit: BoxFit.cover)),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.vermelho, borderRadius: BorderRadius.circular(8)),
                                child: const Text('AO VIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.branco)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${room.currentUsers}/${room.chairs} · ${room.theme}', style: const TextStyle(fontSize: 11, color: AppTheme.cinzaMedio)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.dourado,
        foregroundColor: AppTheme.preto,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createRoom),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RankingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('🥇', 'Estrela VIP', r'R$ 12.450'),
      ('🥈', 'Host Alpha', r'R$ 8.200'),
      ('🥉', 'Charme Plus', r'R$ 6.100'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Ranking Semanal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dourado)),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) => Card(
              color: AppTheme.roxo.withValues(alpha: 0.35),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(e.value.$1, style: const TextStyle(fontSize: 24)),
                title: Text(e.value.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(e.value.$3, style: const TextStyle(color: AppTheme.dourado, fontWeight: FontWeight.bold)),
              ),
            )),
      ],
    );
  }
}
