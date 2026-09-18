import 'package:flutter/material.dart';

/// Paleta compartilhada SOFIA.
class AppColors {
  static const Color fundoPrincipal = Color(0xFF2A1050);
  static const Color roxo = Color(0xFF6A4C93);
  static const Color roxoSuave = Color(0xFF6A4C93);
  static const Color roxoClaro = Color(0xFFB8A0D8);
  static const Color dourado = Color(0xFFFFD700);
  static const Color douradoMet = Color(0xFFFFE55C);
  static const Color lilas = Color(0xFFB8A0D8);
  static const Color amareloOuro = Color(0xFFFFD700);
  static const Color amareloBrilho = Color(0xFFFFFF00);
  static const Color branco = Colors.white;
  static const Color textoClaro = Color(0xFFF8F0FF);
  static const Color botaoFundo = Color(0xFF7B52AE);
  static const Color amarelo = Color(0xFFFFD700);
  static const Color preto = Colors.black;
  static const Color cinzaClaro = Color(0xFFF5F5F5);
  static const Color cinzaMedio = Color(0xFF9E9E9E);
  static const Color cinzaEscuro = Color(0xFF424242);
  static const Color verde = Color(0xFF4CAF50);
  static const Color vermelho = Color(0xFFE53935);

  static const LinearGradient gradienteRoxoDourado = LinearGradient(
    colors: [roxo, dourado],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteLilasRoxo = LinearGradient(
    colors: [lilas, roxo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteDouradoLilas = LinearGradient(
    colors: [dourado, lilas],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
