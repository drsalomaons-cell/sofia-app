import 'package:flutter/material.dart';

/// Avatar circular com moldura PNG real do Stitch.
class AvatarComMoldura extends StatelessWidget {
  final String? fotoUrl;
  final String tipo;
  final int nivel;
  final double tamanho;
  const AvatarComMoldura({super.key, this.fotoUrl, this.tipo = 'host', this.nivel = 1, this.tamanho = 56});
  String get _asset {
    final index = nivel.clamp(1, tipo.toLowerCase() == 'oficial' ? 5 : 6);
    return 'assets/images/frames/${tipo.toLowerCase() == 'oficial' ? 'oficial' : 'host'}$index.png';
  }
  @override
  Widget build(BuildContext context) => SizedBox(width: tamanho, height: tamanho, child: Stack(fit: StackFit.expand, children: [
    Padding(padding: EdgeInsets.all(tamanho * .17), child: CircleAvatar(backgroundColor: const Color(0xFF20253A), backgroundImage: fotoUrl != null && fotoUrl!.isNotEmpty ? NetworkImage(fotoUrl!) : null, child: fotoUrl == null || fotoUrl!.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null)),
    Image.asset(_asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
  ]));
}
