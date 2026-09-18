import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sofia/services/branding_service.dart';

/// Renderiza capa ativa (PNG criptografado, SVG da API ou asset local).
class SofiaCoverImage extends StatelessWidget {
  final String? coverId;
  final String variant;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SofiaCoverImage({
    super.key,
    this.coverId,
    this.variant = 'background',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BrandingService>(
      builder: (context, branding, _) {
        final id = coverId ?? branding.activeCoverId;
        final content = branding.coverVariant(id, variant) ??
            (variant != 'splash' ? branding.coverVariant(id, 'splash') : null);

        if (content != null && content.hasContent) {
          if (content.isPng && content.imageBytes != null) {
            return Image.memory(
              content.imageBytes!,
              fit: fit,
              width: width,
              height: height,
              gaplessPlayback: true,
            );
          }
          if (content.isSvg && content.svgContent != null) {
            return SvgPicture.string(
              content.svgContent!,
              fit: fit,
              width: width,
              height: height,
            );
          }
        }

        return SvgPicture.asset(
          branding.allCovers.firstWhere((c) => c.id == id, orElse: () => branding.activeCover).assetPath,
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }
}
