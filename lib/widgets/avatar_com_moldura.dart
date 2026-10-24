import 'package:flutter/material.dart';
import 'package:sofia/widgets/frame_avatar.dart';

/// Avatar circular com moldura desenhada em Flutter puro.
/// Mantém compatibilidade com a assinatura legada redirecionando para [FrameAvatar].
class AvatarComMoldura extends StatelessWidget {
  final String? fotoUrl;
  final String tipo;
  final int nivel;
  final double tamanho;

  const AvatarComMoldura({
    super.key,
    this.fotoUrl,
    this.tipo = 'host',
    this.nivel = 1,
    this.tamanho = 56,
  });

  String get _frameId {
    final lower = tipo.toLowerCase().trim();
    if (lower == 'oficial' || lower == 'official') {
      return nivel > 3 ? 'official_admin_a' : (nivel.isEven ? 'official_b' : 'official_a');
    }
    return nivel.isEven ? 'host_b' : 'host_a';
  }

  @override
  Widget build(BuildContext context) {
    return FrameAvatar(
      frameId: _frameId,
      photoUrl: fotoUrl,
      customDiameter: tamanho * 0.72,
      size: tamanho >= 80
          ? FrameAvatarSize.large
          : (tamanho >= 50 ? FrameAvatarSize.medium : FrameAvatarSize.small),
      showPlaque: tamanho >= 46,
    );
  }
}
