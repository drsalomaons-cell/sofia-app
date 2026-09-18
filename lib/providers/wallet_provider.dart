import 'package:flutter/foundation.dart';
import 'package:sofia/models/transaction_model.dart';
import 'package:sofia/models/user_model.dart';
import 'package:sofia/services/economy_service.dart';
import 'package:sofia/services/payment_service.dart';

class WalletProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final EconomyService _economyService = EconomyService();
  
  UserModel? _user;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _balance = 0.0;
  double _coins = 0.0;
  double _diamonds = 0.0;
  String? _vipTag;
  String? _frame;
  String? _levelTitle;
  EconomyRules? _rules;

  UserModel? get user => _user;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _balance;
  double get coins => _coins;
  double get diamonds => _diamonds;
  String? get vipTag => _vipTag;
  String? get frame => _frame;
  String? get levelTitle => _levelTitle;
  EconomyRules? get rules => _rules;
  WalletProvider() {
    // Inicializar com dados do usuário
  }

  void setUser(UserModel user) {
    _user = user;
    _balance = user.balance;
    notifyListeners();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rules = await _economyService.getRules();
      final profile = await _paymentService.getWalletProfile(_user!.id);
      _balance = profile.balance;
      _coins = profile.coins;
      _diamonds = profile.diamonds;
      _vipTag = profile.vipTag;
      _frame = profile.frame;
      _levelTitle = profile.levelTitle;
      _transactions = await _paymentService.getUserTransactions(_user!.id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar transações: $e';
      notifyListeners();
    }
  }

  Future<bool> recharge({
    required double amount,
    required String paymentMethod,
    String? pixKey,
    Map<String, dynamic>? bankData,
  }) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transaction = await _paymentService.createRecharge(
        userId: _user!.id,
        amount: amount,
        paymentMethod: paymentMethod,
        pixKey: pixKey,
        bankData: bankData,
      );
      
      _transactions.insert(0, transaction);
      final profile = await _paymentService.getWalletProfile(_user!.id);
      _balance = profile.balance;
      _coins = profile.coins;
      _diamonds = profile.diamonds;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao realizar recarga: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> withdraw({
    required double amount,
    required String pixKey,
    required Map<String, dynamic> bankData,
  }) async {
    if (_user == null) return false;
    
    if (amount > _balance) {
      _errorMessage = 'Saldo insuficiente';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transaction = await _paymentService.createWithdraw(
        userId: _user!.id,
        amount: amount,
        pixKey: pixKey,
        bankData: bankData,
      );
      
      _transactions.insert(0, transaction);
      final profile = await _paymentService.getWalletProfile(_user!.id);
      _balance = profile.balance;
      _coins = profile.coins;
      _diamonds = profile.diamonds;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao solicitar saque: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> addEarning({
    required String roomId,
    required String roomName,
    required double totalAmount,
    int participantCount = 1,
    bool isHost = false,
    bool roomGoalMet = false,
    bool isOpeningEvent = false,
  }) async {
    if (_user == null) return;
    
    try {
      final transaction = await _paymentService.processRoomEarning(
        userId: _user!.id,
        roomId: roomId,
        roomName: roomName,
        totalAmount: totalAmount,
        participantCount: participantCount,
        isHost: isHost,
        roomGoalMet: roomGoalMet,
        isOpeningEvent: isOpeningEvent,
      );
      
      _transactions.insert(0, transaction);
      final profile = await _paymentService.getWalletProfile(_user!.id);
      _balance = profile.balance;
      _coins = profile.coins;
      _diamonds = profile.diamonds;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao processar ganho: $e';
      notifyListeners();
    }
  }

  Future<void> addReferralEarning({
    required String referredUserId,
    required double amount,
  }) async {
    if (_user == null) return;
    
    try {
      final transaction = await _paymentService.processReferralEarning(
        userId: _user!.id,
        referredUserId: referredUserId,
        amount: amount,
      );
      
      _transactions.insert(0, transaction);
      _balance = await _paymentService.getBalance(_user!.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao processar ganho por indicação: $e';
      notifyListeners();
    }
  }

  Future<String> generatePixQrCode(double amount) async {
    return await _paymentService.generatePixQrCode(amount);
  }

  Future<bool> processPagBankPayment({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required double amount,
  }) async {
    return await _paymentService.processPagBankPayment(
      cardNumber: cardNumber,
      expiry: expiry,
      cvv: cvv,
      amount: amount,
    );
  }

  Future<bool> processPixPayment({
    required String pixKey,
    required double amount,
  }) async {
    return await _paymentService.processPixPayment(
      pixKey: pixKey,
      amount: amount,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}