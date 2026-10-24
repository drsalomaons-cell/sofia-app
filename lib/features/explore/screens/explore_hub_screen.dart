import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/widgets/sofia_cover_image.dart';

/// Explorar → Salas | Eventos | Rankings
class ExploreHubScreen extends StatelessWidget {
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Explorar lista somente salas de voz; eventos e rankings têm telas próprias.
    return _RoomsTab();
  }
}

class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RoomProvider>(
        builder: (context, rooms, _) {
          if (rooms.isLoading && rooms.rooms.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.dourado),
            );
          }
          final list = rooms.voiceRooms;
          if (list.isEmpty) {
            return RefreshIndicator(
              color: AppTheme.dourado,
              onRefresh: rooms.loadActiveRooms,
              child: ListView(
                children: const [
                  SizedBox(height: 110),
                  Icon(
                    Icons.record_voice_over_outlined,
                    size: 44,
                    color: AppTheme.cinzaMedio,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Nenhuma sala de voz nesta região agora',
                      style: TextStyle(color: AppTheme.cinzaMedio),
                    ),
                  ),
                ],
              ),
            );
          }
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
              itemCount: list.length,
              itemBuilder: (context, index) {
                final room = list[index];
                return InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.room,
                    arguments: {
                      'id': room.id,
                      'name': room.name,
                      'theme': room.theme,
                      'chairs': '${room.chairs}',
                      'roomType': room.roomType,
                    },
                  ),
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
                              Opacity(
                                opacity: 0.35,
                                child: SofiaCoverImage(
                                  variant: 'splash',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.vermelho,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'AO VIVO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.branco,
                                    ),
                                  ),
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
                              Text(
                                room.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${room.currentUsers}/${room.chairs} · ${room.theme}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.cinzaMedio,
                                ),
                              ),
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
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.createRoom,
          arguments: {'roomType': 'voice'},
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
