import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _rechargeAmount = 50;
  final _withdrawController = TextEditingController();
  final _pixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _withdrawController.dispose();
    _pixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.dourado,
          labelColor: AppTheme.branco,
          tabs: const [
            Tab(text: 'Saldo'),
            Tab(text: 'Recarga'),
            Tab(text: 'Saque'),
          ],
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.isLoading && wallet.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _BalanceTab(wallet: wallet),
              _RechargeTab(
                wallet: wallet,
                amount: _rechargeAmount,
                onAmountChanged: (v) => setState(() => _rechargeAmount = v),
              ),
              _WithdrawTab(wallet: wallet, amountController: _withdrawController, pixController: _pixController),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceTab extends StatelessWidget {
  final WalletProvider wallet;
  const _BalanceTab({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final earnings = wallet.transactions.where((t) => t.amount > 0).fold<double>(0, (s, t) => s + t.amount);
    final withdraws = wallet.transactions.where((t) => t.amount < 0).fold<double>(0, (s, t) => s + t.amount.abs());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.gradienteRoxoDourado,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Disponível', style: TextStyle(fontSize: 16, color: AppTheme.branco)),
                const SizedBox(height: 10),
                Text(
                  fmt.format(wallet.balance),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.branco),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoCard('Moedas', '${wallet.coins.toStringAsFixed(0)} 🪙', Icons.monetization_on)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoCard('Diamantes', '${wallet.diamonds.toStringAsFixed(0)} 💎', Icons.diamond_outlined)),
                  ],
                ),
                if (wallet.vipTag != null) ...[
                  const SizedBox(height: 12),
                  Text(wallet.vipTag!, style: const TextStyle(color: AppTheme.dourado, fontWeight: FontWeight.bold)),
                ],
                if (wallet.levelTitle != null) ...[
                  const SizedBox(height: 4),
                  Text('Nível: ${wallet.levelTitle}', style: const TextStyle(color: AppTheme.branco, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoCard('Ganhos', fmt.format(earnings), Icons.trending_up)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoCard('Saques', fmt.format(withdraws), Icons.arrow_upward)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Histórico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: wallet.transactions.isEmpty
                ? const Center(child: Text('Nenhuma transação ainda'))
                : ListView.builder(
                    itemCount: wallet.transactions.length,
                    itemBuilder: (context, i) {
                      final tx = wallet.transactions[i];
                      final positive = tx.amount >= 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            positive ? Icons.arrow_downward : Icons.arrow_upward,
                            color: positive ? AppTheme.verde : AppTheme.vermelho,
                          ),
                          title: Text(tx.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt)),
                          trailing: Text(
                            '${positive ? '+' : ''}${fmt.format(tx.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: positive ? AppTheme.verde : AppTheme.vermelho,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.branco.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.dourado, size: 18),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.branco)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.branco)),
        ],
      ),
    );
  }
}

class _RechargeTab extends StatelessWidget {
  final WalletProvider wallet;
  final double amount;
  final ValueChanged<double> onAmountChanged;

  const _RechargeTab({required this.wallet, required this.amount, required this.onAmountChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Valor da Recarga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [50.0, 100.0, 200.0, 500.0].map((v) {
              final selected = amount == v;
              return ChoiceChip(
                label: Text('R\$ ${v.toStringAsFixed(0)}'),
                selected: selected,
                onSelected: (_) => onAmountChanged(v),
                selectedColor: AppTheme.roxo,
                labelStyle: TextStyle(color: selected ? AppTheme.branco : AppTheme.preto),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: wallet.isLoading
                  ? null
                  : () async {
                      final ok = await wallet.recharge(amount: amount, paymentMethod: 'PIX');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Recarga realizada!' : wallet.errorMessage ?? 'Erro'),
                            backgroundColor: ok ? AppTheme.verde : AppTheme.vermelho,
                          ),
                        );
                      }
                    },
              child: const Text('RECARREGAR VIA PIX', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawTab extends StatelessWidget {
  final WalletProvider wallet;
  final TextEditingController amountController;
  final TextEditingController pixController;

  const _WithdrawTab({required this.wallet, required this.amountController, required this.pixController});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: amountController,
            decoration: InputDecoration(
              labelText: 'Valor do saque',
              prefixIcon: const Icon(Icons.attach_money),
              helperText: 'Disponível: ${fmt.format(wallet.balance)}',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pixController,
            decoration: const InputDecoration(labelText: 'Chave PIX', prefixIcon: Icon(Icons.pix)),
          ),
          const SizedBox(height: 8),
          Text(
            'Taxa de saque: até 5% · Prazo: até 3 dias úteis · 1 diamante = 1 moeda',
            style: TextStyle(fontSize: 12, color: AppTheme.cinzaMedio.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: wallet.isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
                      final ok = await wallet.withdraw(
                        amount: amount,
                        pixKey: pixController.text,
                        bankData: {'pix': pixController.text},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Saque solicitado!' : wallet.errorMessage ?? 'Erro'),
                            backgroundColor: ok ? AppTheme.verde : AppTheme.vermelho,
                          ),
                        );
                      }
                    },
              child: const Text('SOLICITAR SAQUE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
