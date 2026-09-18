import 'package:sofia/models/user_model.dart';
import 'package:sofia/models/room_model.dart';
import 'package:sofia/models/transaction_model.dart';
import 'package:sofia/services/api_client.dart';

class AdminService {
  // Painel Central de Administração
  Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await ApiClient.get('/api/admin/stats');
    if (data != null) return data;
    return {
      'totalUsers': 0,
      'activeUsers': 0,
      'activeRooms': 0,
      'totalRevenue': 0.0,
      'monthlyRevenue': 0.0,
      'platformSplit': '50%',
      'distributionSplit': '50%',
    };
  }

  Future<List<UserModel>> getAllUsers({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulação de lista de usuários
    return List.generate(limit, (index) {
      final id = ((page - 1) * limit + index + 1).toString();
      return UserModel(
        id: id,
        name: 'Usuário $id',
        email: 'usuario$id@email.com',
        phone: '(11) 99999-$id',
        gender: index % 2 == 0 ? 'Masculino' : 'Feminino',
        interestedIn: index % 2 == 0 ? 'Mulheres' : 'Homens',
        balance: 100.0 + (index * 50),
        level: (index % 10) + 1,
        points: (index + 1) * 100,
        referrals: index % 5,
        isAdmin: index == 0,
        isRegionalAdmin: index >= 1 && index <= 4,
        region: index >= 1 && index <= 4 ? _getRegion(index) : null,
        createdAt: DateTime.now().subtract(Duration(days: index * 10)),
        lastLogin: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }

  String _getRegion(int index) {
    switch (index) {
      case 1:
        return 'América do Sul';
      case 2:
        return 'América do Norte';
      case 3:
        return 'Ásia';
      case 4:
        return 'África';
      default:
        return 'Europa';
    }
  }

  Future<List<RoomModel>> getAllRooms({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulação de lista de salas
    return List.generate(limit, (index) {
      final id = ((page - 1) * limit + index + 1).toString();
      return RoomModel(
        id: id,
        name: 'Sala $id',
        description: 'Descrição da sala $id',
        theme: ['Festa', 'Conversa', 'Música', 'Jogos'][index % 4],
        chairs: 10 + (index * 2),
        currentUsers: 5 + index,
        hostId: '1',
        hostName: 'Host $id',
        participants: List.generate(5 + index, (i) => i.toString()),
        earnings: 50.0 + (index * 10),
        isActive: index % 10 != 0,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }

  Future<List<TransactionModel>> getAllTransactions({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulação de lista de transações
    return List.generate(limit, (index) {
      final id = ((page - 1) * limit + index + 1).toString();
      return TransactionModel(
        id: id,
        userId: '1',
        type: TransactionType.values[index % 6],
        amount: (index + 1) * 25.0,
        description: 'Transação $id',
        status: TransactionStatus.values[index % 5],
        paymentMethod: index % 2 == 0 ? 'PIX' : 'Cartão',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        completedAt: index % 3 == 0 ? DateTime.now().subtract(Duration(days: index - 1)) : null,
      );
    });
  }

  Future<void> banUser(String userId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implementar banimento de usuário
  }

  Future<void> unbanUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implementar desbanimento
  }

  Future<void> deleteRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implementar exclusão de sala
  }

  Future<void> closeRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implementar fechamento de sala
  }

  Future<void> approveWithdrawal(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implementar aprovação de saque
  }

  Future<void> rejectWithdrawal(String transactionId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implementar rejeição de saque
  }

  Future<void> createRegionalAdmin({
    required String userId,
    required String region,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Criar admin regional
  }

  Future<void> removeRegionalAdmin(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Remover admin regional
  }

  Future<List<Map<String, dynamic>>> getRegionalStats(String region) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulação de estatísticas por região
    return [
      {'country': 'Brasil', 'users': 5000, 'revenue': 50000.0},
      {'country': 'Argentina', 'users': 2000, 'revenue': 20000.0},
      {'country': 'Chile', 'users': 1500, 'revenue': 15000.0},
      {'country': 'Colômbia', 'users': 1200, 'revenue': 12000.0},
    ];
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'apiStatus': 'healthy',
      'databaseStatus': 'healthy',
      'socketStatus': 'healthy',
      'paymentStatus': 'healthy',
      'uptime': '99.9%',
      'responseTime': '120ms',
      'activeConnections': 1250,
    };
  }
}