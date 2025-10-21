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
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    amount: (json['amount'] as num).toDouble(),
    type: json['type'] as String,
    status: json['status'] as String,
    description: json['description'] as String,
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
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
  );
}
