import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/models/room_model.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/routes/app_routes.dart';

class LiveTabScreen extends StatelessWidget {
  const LiveTabScreen({super.key});

  void _createRoom(BuildContext context, String roomType) {
    Navigator.pushNamed(
      context,
      AppRoutes.createRoom,
      arguments: {'roomType': roomType},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17102D), Color(0xFF0B1025), Color(0xFF080A1A)],
        ),
      ),
      child: Consumer<RoomProvider>(
        builder: (context, rooms, _) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.videocam_rounded,
                          title: 'Iniciar Live de Vídeo',
                          subtitle: 'Câmera + chat',
                          accent: const Color(0xFF31D7FF),
                          onTap: () => _createRoom(context, 'video'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.mic_rounded,
                          title: 'Criar Sala de Áudio',
                          subtitle: 'Cadeiras + voz',
                          accent: AppTheme.dourado,
                          onTap: () => _createRoom(context, 'voice'),
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  indicatorColor: AppTheme.dourado,
                  labelColor: AppTheme.dourado,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.graphic_eq_rounded),
                      text: 'Salas de Áudio',
                    ),
                    Tab(
                      icon: Icon(Icons.videocam_rounded),
                      text: 'Lives de Vídeo',
                    ),
                  ],
                ),
                if (rooms.isLoading && rooms.rooms.isEmpty)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.dourado),
                    ),
                  )
                else
                  Expanded(
                    child: TabBarView(
                      children: [
                        _RoomList(
                          rooms: rooms.voiceRooms,
                          emptyTitle: 'Nenhuma sala de áudio ativa',
                          emptyHint: 'Crie uma sala e convide sua comunidade.',
                          icon: Icons.mic_none_rounded,
                          onRefresh: rooms.loadActiveRooms,
                        ),
                        _RoomList(
                          rooms: rooms.videoRooms,
                          emptyTitle: 'Nenhuma Live de vídeo ativa',
                          emptyHint: 'Inicie uma Live para aparecer aqui.',
                          icon: Icons.videocam_off_outlined,
                          onRefresh: rooms.loadActiveRooms,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC14182F),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.18), const Color(0xFF10152F)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  final List<RoomModel> rooms;
  final String emptyTitle;
  final String emptyHint;
  final IconData icon;
  final Future<void> Function() onRefresh;

  const _RoomList({
    required this.rooms,
    required this.emptyTitle,
    required this.emptyHint,
    required this.icon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.dourado,
      onRefresh: onRefresh,
      child: rooms.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 45),
                Icon(icon, size: 54, color: Colors.white30),
                const SizedBox(height: 14),
                Text(
                  emptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final isVideo = room.roomType == 'video';
                final accent = isVideo
                    ? const Color(0xFF31D7FF)
                    : AppTheme.dourado;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.38)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SofiaPremiumTheme.purple.withValues(alpha: 0.82),
                        SofiaPremiumTheme.darkBg.withValues(alpha: 0.98),
                      ],
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.15),
                        border: Border.all(color: accent, width: 1.5),
                      ),
                      child: Icon(
                        isVideo ? Icons.videocam_rounded : Icons.mic_rounded,
                        color: accent,
                      ),
                    ),
                    title: Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${room.currentUsers} online • ${room.chairs} lugares • ${isVideo ? 'Vídeo' : 'Áudio'}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: accent),
                  ),
                );
              },
            ),
    );
  }
}
