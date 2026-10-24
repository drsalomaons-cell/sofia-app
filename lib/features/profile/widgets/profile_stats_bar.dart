import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/models/user_model.dart';

/// Barra de contadores (seguidores, seguindo, visitas) e botões de ação.
class ProfileStatsBar extends StatelessWidget {
  final UserModel? user;
  final bool isSelf;
  final VoidCallback onEditProfile;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;

  const ProfileStatsBar({
    super.key,
    required this.user,
    this.isSelf = true,
    required this.onEditProfile,
    this.onFollow,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Contadores numéricos
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0x77151A34),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Seguidores', user?.followersCount ?? 0),
              _divider(),
              _statItem('Seguindo', user?.followingCount ?? 0),
              _divider(),
              _statItem('Visitas', user?.visitorsCount ?? 0),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Botões de ação
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isSelf
              ? SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Editar Perfil',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x33FFD76A),
                      foregroundColor: AppTheme.dourado,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppTheme.dourado.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: onFollow,
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text(
                            'Seguir',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dourado,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: onMessage,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                          label: const Text(
                            'Mensagem',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF31D7FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _statItem(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.cinzaMedio,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
