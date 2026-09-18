import 'package:flutter/material.dart';

/// Agrupa botões com espaçamento consistente (layout 390px).
class SofiaButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const SofiaButtonGroup({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(SizedBox(height: spacing));
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
}
