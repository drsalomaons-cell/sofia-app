import 'package:flutter/material.dart';
import 'package:sofia/features/sunlight/theme/sunlight_room_layout.dart';

/// Atalho fixo do foguete de sala: abre o ranking/participantes, não envia presente.
class SofiaPremiumVipGiftButton extends StatelessWidget {
  final String? roomId;
  final String roomName;
  final bool isHost;
  final int participantCount;
  final VoidCallback onRocketTap;
  final String? topContributorName;
  final String? topContributorPhotoUrl;

  const SofiaPremiumVipGiftButton({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.isHost,
    required this.participantCount,
    required this.onRocketTap,
    this.topContributorName,
    this.topContributorPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scale = SunlightRoomLayout.compactScale(context);

    return Positioned(
      right: 12 * scale,
      bottom: 72 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRocketTap,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 10 * scale,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6807BA), Color(0xFF00F2FE)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (topContributorName != null)
                      CircleAvatar(
                        radius: 13 * scale,
                        backgroundImage:
                            topContributorPhotoUrl != null &&
                                topContributorPhotoUrl!.isNotEmpty
                            ? NetworkImage(topContributorPhotoUrl!)
                            : null,
                        child:
                            topContributorPhotoUrl == null ||
                                topContributorPhotoUrl!.isEmpty
                            ? Text(
                                topContributorName!.isEmpty
                                    ? '?'
                                    : topContributorName!
                                          .substring(0, 1)
                                          .toUpperCase(),
                                style: TextStyle(fontSize: 11 * scale),
                              )
                            : null,
                      )
                    else
                      Text('🚀', style: TextStyle(fontSize: 20 * scale)),
                    SizedBox(width: 6 * scale),
                    Text(
                      topContributorName == null
                          ? 'Sala'
                          : topContributorName!.split(' ').first,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Ranking da sala',
            style: TextStyle(color: Colors.white70, fontSize: 9 * scale),
          ),
        ],
      ),
    );
  }
}
