import 'package:flutter/material.dart';

/// Shell móvel responsivo: ocupa a tela real do aparelho, sem miniaturizar
/// a aplicação num canvas fixo de 390×667.
class SofiaMobileShell extends StatelessWidget {
  final Widget child;

  const SofiaMobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF080A1A),
      child: Material(
        color: const Color(0xFF080A1A),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
