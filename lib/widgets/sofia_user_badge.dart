import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/widgets/frame_avatar.dart';

/// Badge de identificação do usuário com moldura real desenhada via [FrameAvatar],
/// nível de conta e tag VIP.
class SofiaUserBadge extends StatelessWidget {
  final int level;
  final String? levelTitle;
  final String? vipTag;
  final String? frame;
  final double size;
  final String? photoUrl;
  final String? gender;

  const SofiaUserBadge({
    super.key,
    required this.level,
    this.levelTitle,
    this.vipTag,
    this.frame,
    this.size = 48,
    this.photoUrl,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FrameAvatar(
          frameId: frame,
          gender: gender,
          photoUrl: photoUrl,
          name: 'Lv$level',
          customDiameter: size * 0.8,
          size: size >= 70
              ? FrameAvatarSize.large
              : (size >= 44 ? FrameAvatarSize.medium : FrameAvatarSize.small),
          showPlaque: true,
        ),
        if (levelTitle != null && levelTitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            levelTitle!,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.dourado,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (vipTag != null && vipTag!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.dourado.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dourado.withValues(alpha: 0.55)),
            ),
            child: Text(
              vipTag!,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.dourado,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
