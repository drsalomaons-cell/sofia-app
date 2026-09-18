import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/explore/screens/explore_hub_screen.dart';
import 'package:sofia/features/live/screens/live_tab_screen.dart';
import 'package:sofia/features/messages/screens/messages_screen.dart';
import 'package:sofia/features/moments/screens/moments_screen.dart';
import 'package:sofia/features/profile/screens/profile_screen.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/widgets/sofia_cover_image.dart';
import 'package:provider/provider.dart';

/// Shell Sunlight Live adaptado SOFIA — 390×667 via SofiaMobileShell
class MainNavigationShell extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationShell({super.key, required this.onLogout});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 2;

  static const _titles = ['AO VIVO', 'MOMENTOS', 'EXPLORAR', 'MENSAGENS'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        shadowColor: AppTheme.dourado.withValues(alpha: 0.2),
        flexibleSpace: _currentIndex == 2
            ? ClipRect(
                child: Opacity(
                  opacity: 0.15,
                  child: SofiaCoverImage(variant: 'background', fit: BoxFit.cover),
                ),
              )
            : null,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppTheme.dourado,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<WalletProvider>(
            builder: (context, wallet, _) {
              return TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
                icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.dourado, size: 20),
                label: Text(
                  '${wallet.coins.toStringAsFixed(0)} 🪙',
                  style: const TextStyle(color: AppTheme.dourado, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              );
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.roxo,
              child: Icon(Icons.person, size: 16, color: AppTheme.branco),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => ProfileScreen(onLogout: widget.onLogout)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
        index: _currentIndex,
        children: [
          const LiveTabScreen(),
          const MomentsScreen(),
          const ExploreHubScreen(),
          MessagesScreen(onLogout: widget.onLogout),
        ],
      ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.dourado, width: 1.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.dourado,
          unselectedItemColor: AppTheme.cinzaMedio,
          backgroundColor: AppTheme.preto,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Ao Vivo'),
            BottomNavigationBarItem(icon: Icon(Icons.layers_rounded), label: 'Momentos'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explorar'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Mensagens'),
          ],
        ),
      ),
    );
  }
}
