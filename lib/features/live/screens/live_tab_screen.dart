import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/routes/app_routes.dart';

class LiveTabScreen extends StatelessWidget {
  const LiveTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, rooms, _) {
        if (rooms.isLoading && rooms.rooms.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.dourado));
        }
        final list = rooms.rooms;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off_outlined, size: 48, color: AppTheme.cinzaMedio.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                const Text('Nenhuma live no momento', style: TextStyle(color: AppTheme.cinzaMedio)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createRoom),
                  icon: const Icon(Icons.add),
                  label: const Text('Iniciar live'),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.dourado, foregroundColor: AppTheme.preto),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.dourado,
          onRefresh: rooms.loadActiveRooms,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final room = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.room, arguments: {
                    'id': room.id,
                    'name': room.name,
                    'theme': room.theme,
                    'chairs': '${room.chairs}',
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SofiaPremiumTheme.purple.withValues(alpha: 0.85),
                          SofiaPremiumTheme.darkBg.withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SofiaPremiumTheme.gold.withValues(alpha: 0.35)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.gradienteDouradoLilas,
                            border: Border.all(color: AppTheme.dourado, width: 2),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: AppTheme.preto, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.branco)),
                              const SizedBox(height: 4),
                              Text(
                                '${room.currentUsers} espectadores · ${room.chairs} cadeiras · ZEGO',
                                style: const TextStyle(fontSize: 12, color: AppTheme.cinzaMedio),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.vermelho, borderRadius: BorderRadius.circular(8)),
                          child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.branco)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
