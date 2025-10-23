const _undefined = Object();

class SavingsGoalDraftModel {
  /// Sentinel used by [copyWith] to differentiate between no-change and `null`.
  static const Object noChange = _undefined;

  const SavingsGoalDraftModel({
    required this.id,
    this.title,
    this.category,
    this.targetAmount,
    this.monthlyContribution,
    this.deadline,
    this.autoDeposit = false,
    this.motivation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? title;
  final String? category;
  final double? targetAmount;
  final double? monthlyContribution;
  final DateTime? deadline;
  final bool autoDeposit;
  final String? motivation;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalDraftModel copyWith({
    String? id,
    Object? title = _undefined,
    Object? category = _undefined,
    Object? targetAmount = _undefined,
    Object? monthlyContribution = _undefined,
    Object? deadline = _undefined,
    bool? autoDeposit,
    Object? motivation = _undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalDraftModel(
      id: id ?? this.id,
      title: identical(title, _undefined) ? this.title : title as String?,
      category: identical(category, _undefined) ? this.category : category as String?,
      targetAmount: identical(targetAmount, _undefined)
          ? this.targetAmount
          : (targetAmount as double?),
      monthlyContribution: identical(monthlyContribution, _undefined)
          ? this.monthlyContribution
          : (monthlyContribution as double?),
      deadline: identical(deadline, _undefined) ? this.deadline : deadline as DateTime?,
      autoDeposit: autoDeposit ?? this.autoDeposit,
      motivation:
          identical(motivation, _undefined) ? this.motivation : motivation as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'targetAmount': targetAmount,
        'monthlyContribution': monthlyContribution,
        'deadline': deadline?.toIso8601String(),
        'autoDeposit': autoDeposit,
        'motivation': motivation,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavingsGoalDraftModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalDraftModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      category: json['category'] as String?,
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      monthlyContribution: (json['monthlyContribution'] as num?)?.toDouble(),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      autoDeposit: (json['autoDeposit'] as bool?) ?? false,
      motivation: json['motivation'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
