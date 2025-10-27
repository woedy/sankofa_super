class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => currentAmount / targetAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': deadline.toIso8601String(),
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) => SavingsGoalModel(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        title: json['title'] as String,
        targetAmount: _parseDouble(json['targetAmount']),
        currentAmount: _parseDouble(json['currentAmount']),
        deadline: DateTime.parse(json['deadline'] as String),
        category: json['category'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  factory SavingsGoalModel.fromApi(Map<String, dynamic> json) =>
      SavingsGoalModel.fromJson(json);

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavingsGoalModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    deadline: deadline ?? this.deadline,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
