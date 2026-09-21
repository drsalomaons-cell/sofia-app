import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/widgets/sofia_cover_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _redirectTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      while (authProvider.isLoading && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      final initialRoute = authProvider.isAuthenticated
          ? AppRoutes.home
          : AppRoutes.login;
      Navigator.pushReplacementNamed(context, initialRoute);
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SofiaCoverBackground(
        opacity: 0.35,
        variant: 'splash',
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.gradienteRoxoDourado,
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.branco,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.preto.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) => const Icon(
                          Icons.auto_awesome,
                          size: 80,
                          color: AppTheme.roxo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'SOFIA',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.branco,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Social Platform',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.dourado,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.branco,
                      ),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
