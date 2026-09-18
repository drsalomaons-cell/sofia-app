class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String description;
  final String? roomId;
  final String? roomName;
  final TransactionStatus status;
  final String? paymentMethod;
  final String? pixKey;
  final String? bankData;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.roomId,
    this.roomName,
    required this.status,
    this.paymentMethod,
    this.pixKey,
    this.bankData,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? description,
    String? roomId,
    String? roomName,
    TransactionStatus? status,
    String? paymentMethod,
    String? pixKey,
    String? bankData,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pixKey: pixKey ?? this.pixKey,
      bankData: bankData ?? this.bankData,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'amount': amount,
      'description': description,
      'roomId': roomId,
      'roomName': roomName,
      'status': status.toString(),
      'paymentMethod': paymentMethod,
      'pixKey': pixKey,
      'bankData': bankData,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['userId'],
      type: _parseType(json['type']?.toString()),
      amount: json['amount']?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      roomId: json['roomId'],
      roomName: json['roomName'],
      status: _parseStatus(json['status']?.toString()),
      paymentMethod: json['paymentMethod'],
      pixKey: json['pixKey'],
      bankData: json['bankData']?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      cancellationReason: json['cancellationReason'],
    );
  }

  static TransactionType _parseType(String? raw) {
    final s = (raw ?? '').replaceAll('TransactionType.', '');
    return TransactionType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TransactionType.recharge,
    );
  }

  static TransactionStatus _parseStatus(String? raw) {
    final s = (raw ?? '').replaceAll('TransactionStatus.', '');
    return TransactionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TransactionStatus.pending,
    );
  }
}

enum TransactionType {
  recharge, // Recarga de moedas
  withdraw, // Saque
  earning, // Ganho em sala
  referral, // Ganho por indicação
  commission, // Comissão da plataforma
  refund, // Reembolso
}

enum TransactionStatus {
  pending, // Pendente
  processing, // Processando
  completed, // Concluída
  failed, // Falhou
  cancelled, // Cancelada
}