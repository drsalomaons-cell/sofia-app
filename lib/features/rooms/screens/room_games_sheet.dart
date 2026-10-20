import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/services/api_client.dart';

class RoomGamesSheet extends StatefulWidget {
  final String? roomId;
  final bool canStartGame;
  const RoomGamesSheet({
    super.key,
    required this.roomId,
    required this.canStartGame,
  });

  static Future<void> show(
    BuildContext context, {
    String? roomId,
    required bool canStartGame,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF171323),
    builder: (_) => RoomGamesSheet(roomId: roomId, canStartGame: canStartGame),
  );

  @override
  State<RoomGamesSheet> createState() => _RoomGamesSheetState();
}

class _RoomGamesSheetState extends State<RoomGamesSheet> {
  int _bet = 10;
  bool _busy = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _play() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _busy) return;
    if (!widget.canStartGame) {
      setState(() => _error = 'Aguardando o dono da sala iniciar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id =
          user.id + '-' + DateTime.now().microsecondsSinceEpoch.toString();
      final response = await ApiClient.postRaw('/api/games/dice', {
        'userId': user.id,
        'roomId': widget.roomId,
        'bet': _bet,
        'requestId': id,
      });
      if (response == null) throw Exception('Resposta inválida do servidor.');
      if (!mounted) return;
      final status = response['_status'] as int? ?? 500;
      if (status >= 200 && status < 300 && response['result'] is Map) {
        setState(
          () => _result = Map<String, dynamic>.from(response['result'] as Map),
        );
        await context.read<WalletProvider>().loadTransactions();
      } else {
        setState(
          () => _error =
              response['error']?.toString() ?? 'Não foi possível jogar.',
        );
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<WalletProvider>().balance;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sports_esports,
                  color: AppTheme.dourado,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Jogos da sala',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            Text(
              'Saldo disponível: ' + balance.toStringAsFixed(0) + ' moedas',
              style: const TextStyle(color: Colors.white70),
            ),
            if (!widget.canStartGame)
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  'Aguardando o dono da sala iniciar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.dourado.withValues(alpha: .45),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF33234D), Color(0xFF171323)],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.casino, size: 52, color: AppTheme.dourado),
                  const SizedBox(height: 8),
                  const Text(
                    'DADOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resultado sorteado no servidor. Se sair 6, o prêmio é 5× a aposta, incluindo a aposta devolvida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [10, 25, 50, 100]
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value.toString()),
                            selected: _bet == value,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() => _bet = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy || !widget.canStartGame || balance < _bet
                          ? null
                          : _play,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.casino),
                      label: Text(
                        _busy
                            ? 'Jogando…'
                            : 'Apostar ' + _bet.toString() + ' moedas',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Text(
                'Resultado: ' + (_result!['roll']?.toString() ?? '?'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.dourado,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _result!['won'] == true
                    ? 'Você ganhou ' +
                          (_result!['payout']?.toString() ?? '0') +
                          ' moedas!'
                    : 'Não foi desta vez. Aposta perdida.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Saldo atualizado: ' + (_result!['balance']?.toString() ?? '—'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
