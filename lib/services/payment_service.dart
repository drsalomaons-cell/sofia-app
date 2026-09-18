import 'package:sofia/models/transaction_model.dart';
import 'package:sofia/services/api_client.dart';
import 'package:sofia/services/economy_service.dart';

class PaymentService {
  final EconomyService _economy = EconomyService();

  Future<WalletProfile> getWalletProfile(String userId) =>
      _economy.getWalletProfile(userId);  Future<TransactionModel> createRecharge({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? pixKey,
    Map<String, dynamic>? bankData,
  }) async {
    final data = await ApiClient.post('/api/wallet/recharge', {
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'pixKey': pixKey,
    });
    if (data != null && data['transaction'] != null) {
      return TransactionModel.fromJson(Map<String, dynamic>.from(data['transaction'] as Map));
    }
    return TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: TransactionType.recharge,
      amount: amount,
      description: 'Recarga de moedas',
      status: TransactionStatus.completed,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  Future<TransactionModel> createWithdraw({
    required String userId,
    required double amount,
    required String pixKey,
    required Map<String, dynamic> bankData,
  }) async {
    final data = await ApiClient.postRaw('/api/wallet/withdraw', {
      'userId': userId,
      'amount': amount,
      'pixKey': pixKey,
      'bankData': bankData,
    });
    if (data != null && data['transaction'] != null) {
      return TransactionModel.fromJson(Map<String, dynamic>.from(data['transaction'] as Map));
    }
    throw Exception(data?['error']?.toString() ?? 'Erro ao solicitar saque');
  }

  Future<TransactionModel> processRoomEarning({
    required String userId,
    required String roomId,
    required String roomName,
    required double totalAmount,
    int participantCount = 1,
    bool isHost = false,
    bool roomGoalMet = false,
    bool isOpeningEvent = false,
  }) async {
    final data = await ApiClient.post('/api/wallet/earning', {
      'userId': userId,
      'roomId': roomId,
      'roomName': roomName,
      'totalAmount': totalAmount,
      'participantCount': participantCount,
      'source': 'room_time',
      'isHost': isHost,
      'roomGoalMet': roomGoalMet,
      'isOpeningEvent': isOpeningEvent,
    });    if (data != null && data['transaction'] != null) {
      return TransactionModel.fromJson(Map<String, dynamic>.from(data['transaction'] as Map));
    }
    final distributionAmount = totalAmount * 0.5;
    return TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: TransactionType.earning,
      amount: distributionAmount,
      description: 'Ganho em sala: $roomName',
      roomId: roomId,
      roomName: roomName,
      status: TransactionStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    final data = await ApiClient.get('/api/wallet/$userId/transactions');
    if (data != null && data['transactions'] is List) {
      return (data['transactions'] as List)
          .map((t) => TransactionModel.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();
    }
    return [];
  }

  Future<double> getBalance(String userId) async {
    final profile = await getWalletProfile(userId);
    return profile.balance;
  }

  Future<String> generatePixQrCode(double amount) async {
    return '00020126580014BR.GOV.BCB.PIX0136${DateTime.now().millisecondsSinceEpoch}520400005303986540${amount.toStringAsFixed(2)}5802BR5925SOFIA6009SAO PAULO62070503***6304';
  }
  Future<bool> processPagBankPayment({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<bool> processPixPayment({
    required String pixKey,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<TransactionModel> processReferralEarning({
    required String userId,
    required String referredUserId,
    required double amount,
  }) async {
    return TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: TransactionType.referral,
      amount: amount,
      description: 'Ganho por indicação',
      status: TransactionStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }
}
