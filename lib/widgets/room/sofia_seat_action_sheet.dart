import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/models/seat_model.dart';

/// Menu de ações de cadeira (padrão Joytox/OpenLive) — Dono/Moderador.
enum SofiaSeatAction { lock, unlock, mute, unmute, kick, invite, promote }

class SofiaSeatActionSheet extends StatelessWidget {
  final int seatIndex;
  final SeatModel seat;
  final bool canModerate;
  final void Function(SofiaSeatAction action) onAction;

  const SofiaSeatActionSheet({
    super.key,
    required this.seatIndex,
    required this.seat,
    required this.canModerate,
    required this.onAction,
  });

  static Future<void> show(
    BuildContext context, {
    required int seatIndex,
    required SeatModel seat,
    required bool canModerate,
    required void Function(SofiaSeatAction action) onAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SofiaSeatActionSheet(
        seatIndex: seatIndex,
        seat: seat,
        canModerate: canModerate,
        onAction: (action) {
          Navigator.pop(context);
          onAction(action);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.preto,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.dourado, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cadeira ${seatIndex + 1}',
                      style: const TextStyle(
                        color: AppTheme.dourado,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.branco),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (!canModerate)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Apenas dono ou moderador pode gerenciar cadeiras.',
                  style: TextStyle(color: AppTheme.cinzaMedio),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              _item(
                icon: seat.isLocked ? Icons.lock_open : Icons.lock,
                title: seat.isLocked ? 'Desbloquear' : 'Bloquear',
                subtitle: seat.isLocked ? 'Permitir entrada nesta cadeira' : 'Impedir novos usuários',
                onTap: () => onAction(seat.isLocked ? SofiaSeatAction.unlock : SofiaSeatAction.lock),
              ),
              if (seat.isOccupied)
                _item(
                  icon: seat.isMuted ? Icons.mic : Icons.mic_off,
                  title: seat.isMuted ? 'Ativar microfone' : 'Silenciar',
                  subtitle: seat.isMuted ? 'Permitir áudio desta cadeira' : 'Mutar microfone desta cadeira',
                  onTap: () => onAction(seat.isMuted ? SofiaSeatAction.unmute : SofiaSeatAction.mute),
                ),
              if (!seat.isLocked && !seat.isOccupied)
                _item(
                  icon: Icons.person_add_alt_1,
                  title: 'Convidar',
                  subtitle: 'Convidar amigos para esta cadeira',
                  onTap: () => onAction(SofiaSeatAction.invite),
                ),
              if (seat.isOccupied && seat.role != 'owner')
                _item(
                  icon: Icons.shield_outlined,
                  title: 'Promover moderador',
                  subtitle: 'Dar permissões de moderação',
                  onTap: () => onAction(SofiaSeatAction.promote),
                  color: AppTheme.lilas,
                ),
              if (seat.isOccupied)
                _item(
                  icon: Icons.person_remove_outlined,
                  title: 'Remover da cadeira',
                  subtitle: 'Expulsar usuário desta cadeira',
                  onTap: () => onAction(SofiaSeatAction.kick),
                  color: AppTheme.vermelho,
                ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.dourado),
      title: Text(title, style: TextStyle(color: color ?? AppTheme.branco, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.cinzaMedio, fontSize: 12)),
      onTap: onTap,
    );
  }
}
