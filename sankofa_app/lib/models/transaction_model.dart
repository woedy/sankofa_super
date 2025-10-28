class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String status;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? channel;
  final double? fee;
  final String? reference;
  final String? counterparty;
  final double? balanceAfter;
  final double? platformBalanceAfter;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.channel,
    this.fee,
    this.reference,
    this.counterparty,
    this.balanceAfter,
    this.platformBalanceAfter,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'amount': amount,
    'type': type,
    'status': status,
    'description': description,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (channel != null) 'channel': channel,
    if (fee != null) 'fee': fee,
    if (reference != null) 'reference': reference,
    if (counterparty != null) 'counterparty': counterparty,
    if (balanceAfter != null) 'balanceAfter': balanceAfter,
    if (platformBalanceAfter != null) 'platformBalanceAfter': platformBalanceAfter,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    amount: _toDouble(json['amount']),
    type: json['type'] as String,
    status: json['status'] as String,
    description: json['description'] as String,
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    channel: json['channel'] as String?,
    fee: _toDoubleOrNull(json['fee']),
    reference: json['reference'] as String?,
    counterparty: json['counterparty'] as String?,
    balanceAfter: _toDoubleOrNull(json['balanceAfter']),
    platformBalanceAfter: _toDoubleOrNull(json['platformBalanceAfter']),
  );

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? status,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? channel,
    double? fee,
    String? reference,
    String? counterparty,
    double? balanceAfter,
    double? platformBalanceAfter,
  }) => TransactionModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
    status: status ?? this.status,
    description: description ?? this.description,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
        channel: channel ?? this.channel,
        fee: fee ?? this.fee,
        reference: reference ?? this.reference,
        counterparty: counterparty ?? this.counterparty,
        balanceAfter: balanceAfter ?? this.balanceAfter,
        platformBalanceAfter: platformBalanceAfter ?? this.platformBalanceAfter,
      );

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    throw ArgumentError('Unsupported amount value: $value');
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
