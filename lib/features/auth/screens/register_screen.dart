import 'package:flutter/material.dart';
import 'package:sofia/features/auth/screens/login_screen.dart';

/// O cadastro agora vive na tela de entrada (Google/Facebook/Telefone/E-mail).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const LoginScreen(initialEmailMode: true, initialCreate: true);
}