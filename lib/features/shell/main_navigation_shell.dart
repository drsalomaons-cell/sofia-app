import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/explore/screens/explore_hub_screen.dart';
import 'package:sofia/features/live/screens/live_tab_screen.dart';
import 'package:sofia/features/messages/screens/messages_screen.dart';
import 'package:sofia/features/moments/screens/moments_screen.dart';
import 'package:sofia/features/profile/screens/profile_screen.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/routes/app_routes.dart';

/// Navegação principal premium: Início, Momentos, Ao Vivo, Mensagens e Perfil.
class MainNavigationShell extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationShell({super.key, required this.onLogout});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  static const _titles = [
    'INÍCIO',
    'MOMENTOS',
    'AO VIVO',
    'MENSAGENS',
    'MEU PERFIL',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF080A1A),
        shadowColor: AppTheme.dourado.withValues(alpha: 0.2),
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppTheme.dourado,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<WalletProvider>(
            builder: (context, wallet, _) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
                icon: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.dourado,
                  size: 19,
                ),
                label: Text(
                  wallet.coins.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppTheme.dourado,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x331E2344),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: AppTheme.dourado.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const ExploreHubScreen(),
            const MomentsScreen(),
            const LiveTabScreen(),
            MessagesScreen(onLogout: widget.onLogout),
            ProfileScreen(onLogout: widget.onLogout, showAppBar: false),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1024),
          border: Border(
            top: BorderSide(
              color: AppTheme.dourado.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.dourado,
          unselectedItemColor: AppTheme.cinzaMedio,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_filled, size: 27),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_mosaic_outlined),
              activeIcon: Icon(Icons.auto_awesome_mosaic_rounded, size: 27),
              label: 'Momentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_camera_front_outlined),
              activeIcon: Icon(Icons.video_camera_front_rounded, size: 27),
              label: 'Ao Vivo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded, size: 27),
              label: 'Mensagens',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, size: 27),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
