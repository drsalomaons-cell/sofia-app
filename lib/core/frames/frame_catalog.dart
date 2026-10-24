import 'package:flutter/material.dart';

/// Tipos de molduras disponíveis no SOFIA.
enum FrameType {
  baby,
  official,
  officialAdmin,
  room,
  face,
  host,
  vip,
}

extension FrameTypeExtension on FrameType {
  String get rawValue {
    switch (this) {
      case FrameType.baby:
        return 'baby';
      case FrameType.official:
        return 'official';
      case FrameType.officialAdmin:
        return 'official_admin';
      case FrameType.room:
        return 'room';
      case FrameType.face:
        return 'face';
      case FrameType.host:
        return 'host';
      case FrameType.vip:
        return 'vip';
    }
  }

  String get defaultTitle {
    switch (this) {
      case FrameType.baby:
        return 'Bebê';
      case FrameType.official:
        return 'Oficial';
      case FrameType.officialAdmin:
        return 'Adm Oficial';
      case FrameType.room:
        return 'Sala';
      case FrameType.face:
        return 'Rosto';
      case FrameType.host:
        return 'Host';
      case FrameType.vip:
        return 'VIP';
    }
  }
}

/// Estilos visuais de cada tipo de moldura (A e B).
enum FrameStyle {
  a,
  b,
}

extension FrameStyleExtension on FrameStyle {
  String get code => this == FrameStyle.a ? 'A' : 'B';
}

/// Níveis de raridade das molduras.
enum FrameRarity {
  common,
  rare,
  epic,
  legendary,
  mythic,
}

extension FrameRarityExtension on FrameRarity {
  String get label {
    switch (this) {
      case FrameRarity.common:
        return 'Comum';
      case FrameRarity.rare:
        return 'Raro';
      case FrameRarity.epic:
        return 'Épico';
      case FrameRarity.legendary:
        return 'Lendário';
      case FrameRarity.mythic:
        return 'Mítico';
    }
  }

  Color get color {
    switch (this) {
      case FrameRarity.common:
        return const Color(0xFF9E9E9E);
      case FrameRarity.rare:
        return const Color(0xFF00E5FF);
      case FrameRarity.epic:
        return const Color(0xFFB388FF);
      case FrameRarity.legendary:
        return const Color(0xFFFFD700);
      case FrameRarity.mythic:
        return const Color(0xFFFF4081);
    }
  }
}

/// Paleta de cores selecionada para a moldura e plaqueta.
class FramePalette {
  final List<Color> borderGradient;
  final Color glowColor;
  final Color accentColor;
  final List<Color> plaqueGradient;
  final Color plaqueBorderColor;
  final Color plaqueTextColor;

  const FramePalette({
    required this.borderGradient,
    required this.glowColor,
    required this.accentColor,
    required this.plaqueGradient,
    required this.plaqueBorderColor,
    required this.plaqueTextColor,
  });
}

/// Representa uma moldura do catálogo.
class FrameItem {
  final String id;
  final FrameType type;
  final FrameStyle style;
  final String displayName;
  final String description;
  final int minLevel;
  final FrameRarity rarity;
  final FramePalette malePalette;
  final FramePalette femalePalette;
  final FramePalette unisexPalette;

  const FrameItem({
    required this.id,
    required this.type,
    required this.style,
    required this.displayName,
    required this.description,
    required this.minLevel,
    required this.rarity,
    required this.malePalette,
    required this.femalePalette,
    required this.unisexPalette,
  });

  /// Retorna a paleta correta de acordo com o gênero informado.
  FramePalette getPalette(String? gender) {
    if (gender == null || gender.isEmpty) return unisexPalette;
    final lower = gender.toLowerCase().trim();
    if (lower.startsWith('m') || lower.contains('masculin') || lower == 'homem') {
      return malePalette;
    }
    if (lower.startsWith('f') || lower.contains('feminin') || lower == 'mulher') {
      return femalePalette;
    }
    return unisexPalette;
  }
}

/// Catálogo único e centralizado de molduras do SOFIA.
class FrameCatalog {
  FrameCatalog._();

  // ──────────────────────────────────────────────────────────────────────────
  // 1. BEBÊ (baby_a, baby_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem babyA = FrameItem(
    id: 'baby_a',
    type: FrameType.baby,
    style: FrameStyle.a,
    displayName: 'Bebê',
    description: 'Aura suave com micro-esferas e brilho terno.',
    minLevel: 1,
    rarity: FrameRarity.common,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF80D8FF), Color(0xFF0091EA), Color(0xFF82B1FF)],
      glowColor: Color(0x7740C4FF),
      accentColor: Color(0xFFB3E5FC),
      plaqueGradient: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      plaqueBorderColor: Color(0xFF80D8FF),
      plaqueTextColor: Color(0xFFE1F5FE),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF80AB), Color(0xFFF50057), Color(0xFFFF4081)],
      glowColor: Color(0x77FF4081),
      accentColor: Color(0xFFFFD180),
      plaqueGradient: [Color(0xFF880E4F), Color(0xFFC2185B)],
      plaqueBorderColor: Color(0xFFFF80AB),
      plaqueTextColor: Color(0xFFFCE4EC),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFA7FFEB), Color(0xFF00BFA5), Color(0xFF64FFDA)],
      glowColor: Color(0x771DE9B6),
      accentColor: Color(0xFFE0F2F1),
      plaqueGradient: [Color(0xFF004D40), Color(0xFF00796B)],
      plaqueBorderColor: Color(0xFFA7FFEB),
      plaqueTextColor: Color(0xFFE0F2F1),
    ),
  );

  static const FrameItem babyB = FrameItem(
    id: 'baby_b',
    type: FrameType.baby,
    style: FrameStyle.b,
    displayName: 'Bebê',
    description: 'Anéis duplos sonhadores com constelação de estrelas.',
    minLevel: 2,
    rarity: FrameRarity.rare,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF00E5FF), Color(0xFF2979FF), Color(0xFF651FFF)],
      glowColor: Color(0x882979FF),
      accentColor: Color(0xFF80D8FF),
      plaqueGradient: [Color(0xFF1A237E), Color(0xFF283593)],
      plaqueBorderColor: Color(0xFF00E5FF),
      plaqueTextColor: Colors.white,
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF4081), Color(0xFFFF80AB), Color(0xFFFFD54F)],
      glowColor: Color(0x88FF4081),
      accentColor: Color(0xFFFFEB3B),
      plaqueGradient: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
      plaqueBorderColor: Color(0xFFFF80AB),
      plaqueTextColor: Colors.white,
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00B0FF)],
      glowColor: Color(0x8800E676),
      accentColor: Color(0xFFB9F6CA),
      plaqueGradient: [Color(0xFF004D40), Color(0xFF00695C)],
      plaqueBorderColor: Color(0xFF69F0AE),
      plaqueTextColor: Colors.white,
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 2. OFICIAL (official_a, official_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem officialA = FrameItem(
    id: 'official_a',
    type: FrameType.official,
    style: FrameStyle.a,
    displayName: 'Oficial',
    description: 'Moldura institucional metálica com selo de verificação.',
    minLevel: 3,
    rarity: FrameRarity.rare,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF00C6FF)],
      glowColor: Color(0x8800C6FF),
      accentColor: Color(0xFFE0F7FA),
      plaqueGradient: [Color(0xFF0B192C), Color(0xFF1E3E62)],
      plaqueBorderColor: Color(0xFF00F2FE),
      plaqueTextColor: Color(0xFF00F2FE),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
      glowColor: Color(0x88FF6A88),
      accentColor: Color(0xFFFFF0F5),
      plaqueGradient: [Color(0xFF3B0024), Color(0xFF740938)],
      plaqueBorderColor: Color(0xFFFF6A88),
      plaqueTextColor: Color(0xFFFFD2DC),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFF43E97B), Color(0xFF38F9D7), Color(0xFF00F2FE)],
      glowColor: Color(0x8838F9D7),
      accentColor: Color(0xFFE8F5E9),
      plaqueGradient: [Color(0xFF052B24), Color(0xFF0D5C4A)],
      plaqueBorderColor: Color(0xFF38F9D7),
      plaqueTextColor: Color(0xFFE0F7FA),
    ),
  );

  static const FrameItem officialB = FrameItem(
    id: 'official_b',
    type: FrameType.official,
    style: FrameStyle.b,
    displayName: 'Oficial',
    description: 'Borda chanfrada de alta precisão com feixe de luz dinâmico.',
    minLevel: 4,
    rarity: FrameRarity.epic,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF2193B0), Color(0xFF6DD5ED), Color(0xFF1A2A6C)],
      glowColor: Color(0x996DD5ED),
      accentColor: Color(0xFFB2EBF2),
      plaqueGradient: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
      plaqueBorderColor: Color(0xFF6DD5ED),
      plaqueTextColor: Colors.white,
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFEE9CA7), Color(0xFFFFDDE1), Color(0xFFD4145A)],
      glowColor: Color(0x99D4145A),
      accentColor: Color(0xFFFFF1F2),
      plaqueGradient: [Color(0xFF3A001E), Color(0xFF5C0030)],
      plaqueBorderColor: Color(0xFFEE9CA7),
      plaqueTextColor: Colors.white,
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFF00C9FF), Color(0xFF92FE9D), Color(0xFF00F2FE)],
      glowColor: Color(0x9900C9FF),
      accentColor: Colors.white,
      plaqueGradient: [Color(0xFF062226), Color(0xFF0D474F)],
      plaqueBorderColor: Color(0xFF92FE9D),
      plaqueTextColor: Colors.white,
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 3. ADM OFICIAL (official_admin_a, official_admin_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem officialAdminA = FrameItem(
    id: 'official_admin_a',
    type: FrameType.officialAdmin,
    style: FrameStyle.a,
    displayName: 'Adm Oficial',
    description: 'Brasão executivo de autoridade com asas angulares douradas.',
    minLevel: 5,
    rarity: FrameRarity.legendary,
    malePalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFF00E5FF), Color(0xFFFFB300), Color(0xFF0D47A1)],
      glowColor: Color(0xAAFFD700),
      accentColor: Color(0xFFFFF9C4),
      plaqueGradient: [Color(0xFF1B1B2F), Color(0xFF162447)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFFFF4081), Color(0xFFFF80AB), Color(0xFF7B1FA2)],
      glowColor: Color(0xAAFF4081),
      accentColor: Color(0xFFFFE082),
      plaqueGradient: [Color(0xFF2C0024), Color(0xFF4A003D)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFE082),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFF00E676), Color(0xFFFFB300), Color(0xFF00B0FF)],
      glowColor: Color(0xAAFFD700),
      accentColor: Color(0xFFFFFDE7),
      plaqueGradient: [Color(0xFF102027), Color(0xFF263238)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
  );

  static const FrameItem officialAdminB = FrameItem(
    id: 'official_admin_b',
    type: FrameType.officialAdmin,
    style: FrameStyle.b,
    displayName: 'Adm Oficial',
    description: 'Escudo imperial de moderação suprema com feixes de quartzo.',
    minLevel: 6,
    rarity: FrameRarity.mythic,
    malePalette: FramePalette(
      borderGradient: [Color(0xFFFFE082), Color(0xFF18FFFF), Color(0xFFFFAB00), Color(0xFF0091EA)],
      glowColor: Color(0xCC00E5FF),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF0A1128), Color(0xFF1C2541)],
      plaqueBorderColor: Color(0xFF00E5FF),
      plaqueTextColor: Color(0xFFE0F7FA),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFFE082), Color(0xFFFF007F), Color(0xFFFFD700), Color(0xFF8E24AA)],
      glowColor: Color(0xCCFF007F),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF340026), Color(0xFF5A0041)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFF0F5),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFF00F2FE), Color(0xFFE040FB), Color(0xFFFFD700)],
      glowColor: Color(0xCCFFD700),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF120E24), Color(0xFF241442)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFE57F),
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 4. SALA (room_a, room_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem roomA = FrameItem(
    id: 'room_a',
    type: FrameType.room,
    style: FrameStyle.a,
    displayName: 'Sala',
    description: 'Anel sônico de áudio com ondas de som estéreo.',
    minLevel: 2,
    rarity: FrameRarity.rare,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF00E5FF), Color(0xFF0072FF), Color(0xFF00C6FF)],
      glowColor: Color(0x8800E5FF),
      accentColor: Color(0xFF80D8FF),
      plaqueGradient: [Color(0xFF001B3A), Color(0xFF003F7F)],
      plaqueBorderColor: Color(0xFF00E5FF),
      plaqueTextColor: Color(0xFFE1F5FE),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF4081), Color(0xFFF06292), Color(0xFFAB47BC)],
      glowColor: Color(0x88FF4081),
      accentColor: Color(0xFFFFD1DC),
      plaqueGradient: [Color(0xFF380026), Color(0xFF6B084E)],
      plaqueBorderColor: Color(0xFFFF4081),
      plaqueTextColor: Color(0xFFFCE4EC),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF6807BA)],
      glowColor: Color(0x8800F2FE),
      accentColor: Color(0xFFE0F7FA),
      plaqueGradient: [Color(0xFF0F0C29), Color(0xFF302B63)],
      plaqueBorderColor: Color(0xFF00F2FE),
      plaqueTextColor: Colors.white,
    ),
  );

  static const FrameItem roomB = FrameItem(
    id: 'room_b',
    type: FrameType.room,
    style: FrameStyle.b,
    displayName: 'Sala',
    description: 'Câmara acústica holográfica com feixes em sincronia.',
    minLevel: 4,
    rarity: FrameRarity.epic,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF11998E), Color(0xFF38EF7D), Color(0xFF00E5FF)],
      glowColor: Color(0x9938EF7D),
      accentColor: Color(0xFFA7FFEB),
      plaqueGradient: [Color(0xFF0A2E24), Color(0xFF145C49)],
      plaqueBorderColor: Color(0xFF38EF7D),
      plaqueTextColor: Color(0xFFE0F2F1),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF0844), Color(0xFFFFB199), Color(0xFFFF4081)],
      glowColor: Color(0x99FF0844),
      accentColor: Color(0xFFFFE0B2),
      plaqueGradient: [Color(0xFF4A0012), Color(0xFF800A26)],
      plaqueBorderColor: Color(0xFFFFB199),
      plaqueTextColor: Colors.white,
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFF77062), Color(0xFFFE5196), Color(0xFF7F00FF)],
      glowColor: Color(0x99FE5196),
      accentColor: Color(0xFFFFD1DC),
      plaqueGradient: [Color(0xFF2C0B35), Color(0xFF55196B)],
      plaqueBorderColor: Color(0xFFFE5196),
      plaqueTextColor: Colors.white,
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 5. ROSTO (face_a, face_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem faceA = FrameItem(
    id: 'face_a',
    type: FrameType.face,
    style: FrameStyle.a,
    displayName: 'Rosto',
    description: 'Borda biométrica de alta definição com mira holográfica.',
    minLevel: 2,
    rarity: FrameRarity.rare,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF00C6FF)],
      glowColor: Color(0x8800F2FE),
      accentColor: Color(0xFF00F2FE),
      plaqueGradient: [Color(0xFF08162A), Color(0xFF123456)],
      plaqueBorderColor: Color(0xFF00F2FE),
      plaqueTextColor: Color(0xFF00F2FE),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF6A88), Color(0xFFFF99AC), Color(0xFFFFB199)],
      glowColor: Color(0x88FF6A88),
      accentColor: Color(0xFFFF6A88),
      plaqueGradient: [Color(0xFF330C1E), Color(0xFF6B1D43)],
      plaqueBorderColor: Color(0xFFFF6A88),
      plaqueTextColor: Color(0xFFFFE3EB),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFB98AFF), Color(0xFF00F2FE), Color(0xFFB98AFF)],
      glowColor: Color(0x88B98AFF),
      accentColor: Color(0xFFE1BEE7),
      plaqueGradient: [Color(0xFF1E1035), Color(0xFF3D1F6D)],
      plaqueBorderColor: Color(0xFFB98AFF),
      plaqueTextColor: Colors.white,
    ),
  );

  static const FrameItem faceB = FrameItem(
    id: 'face_b',
    type: FrameType.face,
    style: FrameStyle.b,
    displayName: 'Rosto',
    description: 'Moldura cyber-glamour geométrica com facetas angulares.',
    minLevel: 5,
    rarity: FrameRarity.legendary,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF7F00FF), Color(0xFFE100FF), Color(0xFF00F2FE)],
      glowColor: Color(0x99E100FF),
      accentColor: Color(0xFFEA80FC),
      plaqueGradient: [Color(0xFF1A0033), Color(0xFF3E0075)],
      plaqueBorderColor: Color(0xFFE100FF),
      plaqueTextColor: Colors.white,
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF007F), Color(0xFFFF758C), Color(0xFFFF7EB3)],
      glowColor: Color(0x99FF007F),
      accentColor: Color(0xFFFF80AB),
      plaqueGradient: [Color(0xFF3D0022), Color(0xFF7A0045)],
      plaqueBorderColor: Color(0xFFFF007F),
      plaqueTextColor: Colors.white,
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFF007F), Color(0xFF00F2FE), Color(0xFFFFD700)],
      glowColor: Color(0x99FF007F),
      accentColor: Colors.white,
      plaqueGradient: [Color(0xFF22092C), Color(0xFF5A1E76)],
      plaqueBorderColor: Color(0xFFFF007F),
      plaqueTextColor: Color(0xFFFFD700),
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 6. HOST (host_a, host_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem hostA = FrameItem(
    id: 'host_a',
    type: FrameType.host,
    style: FrameStyle.a,
    displayName: 'Host',
    description: 'Laureado de transmissão com estrela guia do microfone.',
    minLevel: 1,
    rarity: FrameRarity.common,
    malePalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
      glowColor: Color(0x88FFA000),
      accentColor: Color(0xFFFFF8E1),
      plaqueGradient: [Color(0xFF2E1C00), Color(0xFF5D3900)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF6F91), Color(0xFFFF9671), Color(0xFFFFC75F)],
      glowColor: Color(0x88FF9671),
      accentColor: Color(0xFFFFF3E0),
      plaqueGradient: [Color(0xFF3B151E), Color(0xFF752B3C)],
      plaqueBorderColor: Color(0xFFFF9671),
      plaqueTextColor: Color(0xFFFFE0B2),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFFFF76C8), Color(0xFF31D7FF)],
      glowColor: Color(0x88FFD700),
      accentColor: Colors.white,
      plaqueGradient: [Color(0xFF251132), Color(0xFF4C2366)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
  );

  static const FrameItem hostB = FrameItem(
    id: 'host_b',
    type: FrameType.host,
    style: FrameStyle.b,
    displayName: 'Host',
    description: 'Corona estelar de palco com holofotes em rotação.',
    minLevel: 3,
    rarity: FrameRarity.epic,
    malePalette: FramePalette(
      borderGradient: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFF00E5FF)],
      glowColor: Color(0xAAFFB300),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF1A1A2E), Color(0xFF2E2E48)],
      plaqueBorderColor: Color(0xFFFFB300),
      plaqueTextColor: Color(0xFFFFE082),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF80AB), Color(0xFFFF4081), Color(0xFFFFD700)],
      glowColor: Color(0xAAFF4081),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF380820), Color(0xFF6E1643)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFE082),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFFF857A6), Color(0xFFFF5858)],
      glowColor: Color(0xAAFFD700),
      accentColor: Color(0xFFFFF8E1),
      plaqueGradient: [Color(0xFF360920), Color(0xFF66173E)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Colors.white,
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 7. VIP (vip_a, vip_b)
  // ──────────────────────────────────────────────────────────────────────────
  static const FrameItem vipA = FrameItem(
    id: 'vip_a',
    type: FrameType.vip,
    style: FrameStyle.a,
    displayName: 'VIP',
    description: 'Coroa de nobreza imperial com pedrarias e brilho de diamante.',
    minLevel: 5,
    rarity: FrameRarity.legendary,
    malePalette: FramePalette(
      borderGradient: [Color(0xFFE5E4E2), Color(0xFF00F2FE), Color(0xFFFFD700), Color(0xFF90CAF9)],
      glowColor: Color(0xAA00F2FE),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFFFF69B4), Color(0xFFE040FB), Color(0xFFFF80AB)],
      glowColor: Color(0xAAFF69B4),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF2C0B35), Color(0xFF55196B)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFE082),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFFE0E0E0), Color(0xFFFFC107), Color(0xFFB388FF)],
      glowColor: Color(0xAAFFD700),
      accentColor: Colors.white,
      plaqueGradient: [Color(0xFF1C132B), Color(0xFF382756)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
  );

  static const FrameItem vipB = FrameItem(
    id: 'vip_b',
    type: FrameType.vip,
    style: FrameStyle.b,
    displayName: 'VIP',
    description: 'Joia suprema facetada com prisma cósmico e partículas estelares.',
    minLevel: 7,
    rarity: FrameRarity.mythic,
    malePalette: FramePalette(
      borderGradient: [Color(0xFF7DD3FC), Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFFC084FC)],
      glowColor: Color(0xCC38BDF8),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
      plaqueBorderColor: Color(0xFF7DD3FC),
      plaqueTextColor: Color(0xFF7DD3FC),
    ),
    femalePalette: FramePalette(
      borderGradient: [Color(0xFFFF007F), Color(0xFFFF77A9), Color(0xFFFFD700), Color(0xFFBA68C8)],
      glowColor: Color(0xCCFF007F),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF2A0824), Color(0xFF4C0E41)],
      plaqueBorderColor: Color(0xFFFF77A9),
      plaqueTextColor: Color(0xFFFFF0F5),
    ),
    unisexPalette: FramePalette(
      borderGradient: [Color(0xFFFFD700), Color(0xFF00F2FE), Color(0xFFFF007F), Color(0xFF7B1FA2)],
      glowColor: Color(0xCCFFD700),
      accentColor: Color(0xFFFFFFFF),
      plaqueGradient: [Color(0xFF130924), Color(0xFF2E1754)],
      plaqueBorderColor: Color(0xFFFFD700),
      plaqueTextColor: Color(0xFFFFD700),
    ),
  );

  /// Lista com todos os 14 itens do catálogo de molduras.
  static const List<FrameItem> allFrames = [
    babyA,
    babyB,
    officialA,
    officialB,
    officialAdminA,
    officialAdminB,
    roomA,
    roomB,
    faceA,
    faceB,
    hostA,
    hostB,
    vipA,
    vipB,
  ];

  /// Mapa rápido por ID único.
  static final Map<String, FrameItem> _framesById = {
    for (final frame in allFrames) frame.id: frame,
  };

  /// Mapeamento de compatibilidade para valores legados do app.
  static String normalizeFrameId(String? raw) {
    if (raw == null || raw.trim().isEmpty) return hostA.id;
    final lower = raw.trim().toLowerCase();

    // Compatibilidade com novos IDs
    if (_framesById.containsKey(lower)) return lower;

    // Mapeamento de nomes legados de níveis
    switch (lower) {
      case 'bronze':
        return hostA.id;
      case 'silver':
        return officialA.id;
      case 'gold':
        return officialAdminA.id;
      case 'platinum':
        return vipA.id;
      case 'diamond':
        return vipB.id;
    }

    // Mapeamento de legados host1-6
    if (lower.startsWith('host')) {
      final numStr = lower.replaceAll(RegExp(r'[^0-9]'), '');
      final n = int.tryParse(numStr) ?? 1;
      return n.isEven ? hostB.id : hostA.id;
    }

    // Mapeamento de legados oficial1-5
    if (lower.startsWith('oficial') || lower.startsWith('official')) {
      final numStr = lower.replaceAll(RegExp(r'[^0-9]'), '');
      final n = int.tryParse(numStr) ?? 1;
      return n > 3 ? officialAdminA.id : (n.isEven ? officialB.id : officialA.id);
    }

    // Mapeamento por tipo sem estilo
    switch (lower) {
      case 'baby':
      case 'bebe':
      case 'bebê':
        return babyA.id;
      case 'oficial':
      case 'official':
        return officialA.id;
      case 'admin':
      case 'adm':
      case 'official_admin':
      case 'adm_oficial':
        return officialAdminA.id;
      case 'room':
      case 'sala':
        return roomA.id;
      case 'face':
      case 'rosto':
        return faceA.id;
      case 'host':
        return hostA.id;
      case 'vip':
        return vipA.id;
      default:
        return hostA.id;
    }
  }

  /// Busca um item pelo ID ou retorna null se não existir.
  static FrameItem? findById(String? id) {
    if (id == null) return null;
    return _framesById[normalizeFrameId(id)];
  }

  /// Resolve um FrameItem e sua paleta garantindo sempre um valor válido e seguro.
  static ({FrameItem frame, FramePalette palette}) resolve(
    String? frameIdOrLegacy, {
    String? gender,
  }) {
    final normalizedId = normalizeFrameId(frameIdOrLegacy);
    final frame = _framesById[normalizedId] ?? hostA;
    final palette = frame.getPalette(gender);
    return (frame: frame, palette: palette);
  }

  /// Retorna molduras agrupadas por tipo.
  static Map<FrameType, List<FrameItem>> byType() {
    final map = <FrameType, List<FrameItem>>{};
    for (final frame in allFrames) {
      map.putIfAbsent(frame.type, () => []).add(frame);
    }
    return map;
  }
}
