import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/services/admin_service.dart';
import 'package:sofia/services/branding_service.dart';
import 'package:sofia/widgets/sofia_cover_image.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _adminService.getDashboardStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.dourado,
          labelColor: AppTheme.branco,
          unselectedLabelColor: AppTheme.cinzaMedio,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Usuários'),
            Tab(text: 'Salas'),
            Tab(text: 'Regiões'),
            Tab(text: 'Capas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(stats: _stats, isLoading: _isLoading),
          const _UsersTab(),
          const _RoomsTab(),
          const _RegionsTab(),
          const _CapasTab(),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isLoading;

  const _DashboardTab({required this.stats, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard('Usuários Totais', '${stats?['totalUsers'] ?? 0}', Icons.people, AppTheme.roxo),
          _buildStatCard('Usuários Ativos', '${stats?['activeUsers'] ?? 0}', Icons.person_outline, AppTheme.verde),
          _buildStatCard('Salas Ativas', '${stats?['activeRooms'] ?? 0}', Icons.room, AppTheme.lilas),
          _buildStatCard('Receita Total', 'R\$ ${stats?['totalRevenue']?.toStringAsFixed(0) ?? 0}', Icons.attach_money, AppTheme.dourado),
          _buildStatCard('Receita Mensal', 'R\$ ${stats?['monthlyRevenue']?.toStringAsFixed(0) ?? 0}', Icons.trending_up, AppTheme.verde),
          _buildStatCard('Transações', '${stats?['totalTransactions'] ?? 0}', Icons.swap_horiz, AppTheme.roxo),
          _buildStatCard('Saques Pendentes', '${stats?['pendingWithdrawals'] ?? 0}', Icons.pending, AppTheme.vermelho),
          _buildStatCard('Usuários Banidos', '${stats?['bannedUsers'] ?? 0}', Icons.block, AppTheme.cinzaEscuro),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.cinzaMedio),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AdminService().getAllUsers(page: 1, limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final users = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.roxo,
                  child: Text(user.name[0]),
                ),
                title: Text(user.name),
                subtitle: Text('${user.email} • Nível ${user.level}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.isAdmin)
                      const Icon(Icons.admin_panel_settings, color: AppTheme.dourado, size: 20),
                    if (user.isRegionalAdmin)
                      const Icon(Icons.public, color: AppTheme.lilas, size: 20),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // TODO: Mostrar opções do usuário
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AdminService().getAllRooms(page: 1, limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final rooms = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.gradienteRoxoDourado,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(Icons.room, color: AppTheme.branco),
                ),
                title: Text(room.name),
                subtitle: Text('${room.theme} • ${room.currentUsers}/${room.chairs} usuários'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.vermelho),
                  onPressed: () {
                    // TODO: Confirmar exclusão
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RegionsTab extends StatelessWidget {
  const _RegionsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AdminService().getRegionalStats('América do Sul'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lilas,
                  child: Icon(Icons.public, color: AppTheme.branco),
                ),
                title: Text(stat['country']),
                subtitle: Text('${stat['users']} usuários'),
                trailing: Text(
                  'R\$ ${stat['revenue']?.toStringAsFixed(0) ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.verde,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CapasTab extends StatelessWidget {
  const _CapasTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BrandingService>(
      builder: (context, branding, _) {
        if (branding.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Gerenciamento de Capas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione a capa ativa do aplicativo SOFIA',
              style: TextStyle(color: AppTheme.cinzaMedio),
            ),
            const SizedBox(height: 20),
            ...branding.allCovers.map((cover) {
              final isActive = cover.id == branding.activeCoverId;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isActive ? AppTheme.dourado : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: SofiaCoverImage(
                          coverId: cover.id,
                          variant: 'splash',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cover.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (cover.isProtected)
                                  const Row(
                                    children: [
                                      Icon(Icons.lock_outline, size: 14, color: AppTheme.verde),
                                      SizedBox(width: 4),
                                      Text(
                                        'Protegida',
                                        style: TextStyle(fontSize: 12, color: AppTheme.verde),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.dourado,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ATIVA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.branco,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () async {
                                final ok = await branding.setActiveCover(cover.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Capa "${cover.title}" ativada!'
                                          : 'Erro ao ativar capa'),
                                      backgroundColor: ok ? AppTheme.verde : AppTheme.vermelho,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Ativar'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}