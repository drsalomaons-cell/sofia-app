import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/services/branding_service.dart';
import 'package:sofia/widgets/sofia_cover_image.dart';
import 'package:sofia/widgets/sofia_mobile_shell.dart';

/// Exibe a capa ativa como fundo decorativo (criptografada via API ou asset local).
class SofiaCoverBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final String variant;

  const SofiaCoverBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
    this.variant = 'background',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BrandingService>(
      builder: (context, branding, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: opacity,
              child: SofiaCoverImage(
                coverId: branding.activeCoverId,
                variant: variant,
                fit: BoxFit.cover,
                width: SofiaMobileShell.mobileWidth,
                height: SofiaMobileShell.mobileHeight,
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
