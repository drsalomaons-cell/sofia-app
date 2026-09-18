import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';

class SofiaUserBadge extends StatelessWidget {
  final int level;
  final String? levelTitle;
  final String? vipTag;
  final String? frame;
  final double size;

  const SofiaUserBadge({
    super.key,
    required this.level,
    this.levelTitle,
    this.vipTag,
    this.frame,
    this.size = 48,
  });

  Color get _frameColor {
    switch (frame) {
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return AppTheme.dourado;
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFF7DD3FC);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _frameColor, width: 3),
            boxShadow: [
              BoxShadow(color: _frameColor.withValues(alpha: 0.35), blurRadius: 8),
            ],
          ),
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: AppTheme.roxo,
            child: Text(
              'Lv$level',
              style: TextStyle(
                color: AppTheme.branco,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28,
              ),
            ),
          ),
        ),
        if (levelTitle != null) ...[
          const SizedBox(height: 4),
          Text(
            levelTitle!,
            style: const TextStyle(fontSize: 11, color: AppTheme.dourado, fontWeight: FontWeight.w600),
          ),
        ],
        if (vipTag != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.dourado.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dourado.withValues(alpha: 0.5)),
            ),
            child: Text(vipTag!, style: const TextStyle(fontSize: 10, color: AppTheme.dourado)),
          ),
        ],
      ],
    );
  }
}
