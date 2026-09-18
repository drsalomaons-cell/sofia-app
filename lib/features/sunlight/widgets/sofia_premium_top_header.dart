import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/features/sunlight/theme/sunlight_room_layout.dart';
import 'package:sofia/services/branding_service.dart';
import 'package:sofia/widgets/sofia_cover_image.dart';

class SofiaPremiumTopHeader extends StatelessWidget {
  final String roomName;
  final String roomTheme;
  final VoidCallback? onMenu;

  const SofiaPremiumTopHeader({
    super.key,
    required this.roomName,
    required this.roomTheme,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final scale = SunlightRoomLayout.compactScale(context);
    final coverSize = 52 * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 4, 6, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: coverSize,
              height: coverSize,
              child: Consumer<BrandingService>(
                builder: (_, branding, __) => SofiaCoverImage(variant: 'splash', fit: BoxFit.cover),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: TextStyle(color: SofiaPremiumTheme.goldSoft, fontSize: 15 * scale, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(roomTheme, style: TextStyle(color: Colors.white54, fontSize: 11 * scale)),
                SizedBox(height: 4 * scale),
                SizedBox(
                  height: 22 * scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: SofiaPremiumTheme.purpleDeep.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: SofiaPremiumTheme.gold.withValues(alpha: 0.25)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                        child: Text(
                          SofiaPremiumTheme.communityRules,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 10 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              icon: Icon(Icons.more_vert, color: Colors.white70, size: 22 * scale),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 36 * scale, minHeight: 36 * scale),
            ),
        ],
      ),
    );
  }
}
