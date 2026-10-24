import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/frames/frame_catalog.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/profile/widgets/about_dialog.dart';
import 'package:sofia/features/profile/widgets/charm_dialog.dart';
import 'package:sofia/features/profile/widgets/frame_selector_sheet.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/routes/app_routes.dart';

/// Seção com atalhos interativos do perfil (Carteira, Charme, Molduras, Configurações, Sobre nós).
class ProfileShortcuts extends StatelessWidget {
  const ProfileShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final user = context.watch<AuthProvider>().user;
    final frame = FrameCatalog.findById(user?.effectiveFrameId);
    final frameName = frame != null ? '${frame.displayName} ${frame.style.code}' : 'Host A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATALHOS & SERVIÇOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: AppTheme.cinzaMedio,
            ),
          ),
          const SizedBox(height: 10),

          // 1. Carteira (Saldo de Diamantes e Moedas)
          _shortcutTile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppTheme.dourado,
            title: 'Carteira',
            subtitle: '🪙 ${wallet.coins.toStringAsFixed(0)} Moedas · 💎 ${wallet.diamonds.toStringAsFixed(0)} Diamantes',
            trailingBadge: 'Abrir',
            onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
          ),

          // 2. Charme
          _shortcutTile(
            context,
            icon: Icons.favorite_border_rounded,
            iconColor: const Color(0xFFFF76C8),
            title: 'Charme & Popularidade',
            subtitle: '${user?.charmLevel ?? user?.points ?? 0} pontos acumulados',
            onTap: () => CharmDialog.show(context, user),
          ),

          // 3. Molduras (escolher a equipada)
          _shortcutTile(
            context,
            icon: Icons.filter_frames_outlined,
            iconColor: const Color(0xFF00E5FF),
            title: 'Molduras de Avatar',
            subtitle: 'Equipada: $frameName',
            trailingBadge: 'Trocar',
            onTap: () => FrameSelectorSheet.show(context),
          ),

          // 4. Meus Indicados
          _shortcutTile(
            context,
            icon: Icons.people_outline_rounded,
            iconColor: const Color(0xFF61E6B5),
            title: 'Meus Indicados',
            subtitle: '${user?.referrals ?? 0} amigos convidados',
            onTap: () => Navigator.pushNamed(context, AppRoutes.referrals),
          ),

          // 5. Configurações
          _shortcutTile(
            context,
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFFB98AFF),
            title: 'Configurações',
            subtitle: 'Conta, notificações e preferências',
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),

          // 6. Sobre nós
          _shortcutTile(
            context,
            icon: Icons.info_outline_rounded,
            iconColor: Colors.white70,
            title: 'Sobre nós',
            subtitle: 'Versão do aplicativo e termos',
            onTap: () => ProfileAboutDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _shortcutTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0x66151A34),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.cinzaMedio,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.dourado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dourado.withValues(alpha: 0.4)),
                ),
                child: Text(
                  trailingBadge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dourado,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.white38,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
