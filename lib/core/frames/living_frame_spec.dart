import 'package:flutter/material.dart';

/// Formato do anel da moldura.
enum FrameShape { circle, hexagon, octagon }

/// Raridade visual da moldura.
enum FrameTier { normal, luxury, epic }

/// Efeito animado da moldura.
enum FrameEffect { none, shimmer, orbit, lightning, fire, wings }

/// Função do dono da moldura. Cada função tem plaqueta de nome própria.
enum FrameRole {
  baby,
  official,
  adminOfficial,
  superAdmin,
  bd,
  agency,
  host,
  family,
  vip,
  room,
  face,
}

extension FrameRoleX on FrameRole {
  /// Texto da plaqueta, sempre em destaque.
  String get label {
    switch (this) {
      case FrameRole.baby:
        return 'BEBÊ';
      case FrameRole.official:
        return 'OFICIAL';
      case FrameRole.adminOfficial:
        return 'ADM OFICIAL';
      case FrameRole.superAdmin:
        return 'SUPER ADM';
      case FrameRole.bd:
        return 'BD';
      case FrameRole.agency:
        return 'AGÊNCIA';
      case FrameRole.host:
        return 'HOST';
      case FrameRole.family:
        return 'FAMÍLIA';
      case FrameRole.vip:
        return 'VIP';
      case FrameRole.room:
        return 'SALA';
      case FrameRole.face:
        return 'ROSTO';
    }
  }

  /// Duas cores principais da função (neon e destaque).
  List<Color> get colors {
    switch (this) {
      case FrameRole.baby:
        return const [Color(0xFFFF9AD5), Color(0xFF7DE3FF)];
      case FrameRole.official:
        return const [Color(0xFFFFD36B), Color(0xFFFFF4C9)];
      case FrameRole.adminOfficial:
        return const [Color(0xFF00E5FF), Color(0xFF3D5AFE)];
      case FrameRole.superAdmin:
        return const [Color(0xFFFF2BD6), Color(0xFFFFC857)];
      case FrameRole.bd:
        return const [Color(0xFF00E676), Color(0xFF00B8D4)];
      case FrameRole.agency:
        return const [Color(0xFFFF9100), Color(0xFFFFE082)];
      case FrameRole.host:
        return const [Color(0xFF9C6BFF), Color(0xFF38E8FF)];
      case FrameRole.family:
        return const [Color(0xFFFF6F91), Color(0xFFFFD27A)];
      case FrameRole.vip:
        return const [Color(0xFFFFC400), Color(0xFFFFF176)];
      case FrameRole.room:
        return const [Color(0xFF4F7CFF), Color(0xFFB388FF)];
      case FrameRole.face:
        return const [Color(0xFFCFD8DC), Color(0xFF40C4FF)];
    }
  }

  /// Plaquetas de cor clara usam texto escuro para manter o contraste.
  Color get plaqueTextColor {
    switch (this) {
      case FrameRole.official:
      case FrameRole.vip:
      case FrameRole.face:
      case FrameRole.agency:
      case FrameRole.baby:
        return const Color(0xFF1A1034);
      default:
        return Colors.white;
    }
  }
}

extension FrameTierX on FrameTier {
  String get label {
    switch (this) {
      case FrameTier.normal:
        return 'Normal';
      case FrameTier.luxury:
        return 'Luxuosa';
      case FrameTier.epic:
        return 'Épica';
    }
  }
}

extension FrameEffectX on FrameEffect {
  String get label {
    switch (this) {
      case FrameEffect.none:
        return 'Clássica';
      case FrameEffect.shimmer:
        return 'Brilho';
      case FrameEffect.orbit:
        return 'Órbita';
      case FrameEffect.lightning:
        return 'Trovão';
      case FrameEffect.fire:
        return 'Fogo';
      case FrameEffect.wings:
        return 'Asas';
    }
  }
}

/// Uma moldura da biblioteca. Tudo é desenhado em código.
class LivingFrameSpec {
  const LivingFrameSpec({
    required this.id,
    required this.role,
    required this.tier,
    required this.effect,
    required this.shape,
  });

  final String id;
  final FrameRole role;
  final FrameTier tier;
  final FrameEffect effect;
  final FrameShape shape;

  String get plaque => role.label;
  List<Color> get colors => role.colors;
  String get displayName => '${role.label} ${tier.label} ${effect.label}';
}

/// Biblioteca gerada por combinação: função x raridade x efeito x formato.
class LivingFrameLibrary {
  LivingFrameLibrary._();

  static const Map<FrameTier, List<FrameEffect>> _effectsByTier = {
    FrameTier.normal: [FrameEffect.none, FrameEffect.shimmer],
    FrameTier.luxury: [FrameEffect.shimmer, FrameEffect.orbit],
    FrameTier.epic: [
      FrameEffect.lightning,
      FrameEffect.fire,
      FrameEffect.wings,
    ],
  };

  static final List<LivingFrameSpec> all = List.unmodifiable(_build());

  static final Map<String, LivingFrameSpec> _byId = {
    for (final f in all) f.id: f,
  };

  static LivingFrameSpec? find(String? id) => id == null ? null : _byId[id];

  static List<LivingFrameSpec> byRole(FrameRole role) =>
      all.where((f) => f.role == role).toList();

  static List<LivingFrameSpec> byTier(FrameTier tier) =>
      all.where((f) => f.tier == tier).toList();

  static List<LivingFrameSpec> _build() {
    final list = <LivingFrameSpec>[];
    for (final role in FrameRole.values) {
      for (final tier in FrameTier.values) {
        for (final effect in _effectsByTier[tier]!) {
          for (final shape in FrameShape.values) {
            list.add(
              LivingFrameSpec(
                id: 'lv_${role.name}_${tier.name}_${effect.name}_${shape.name}',
                role: role,
                tier: tier,
                effect: effect,
                shape: shape,
              ),
            );
          }
        }
      }
    }
    return list;
  }
}
