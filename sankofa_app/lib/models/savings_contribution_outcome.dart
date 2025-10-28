import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/transaction_model.dart';

class WalletSnapshot {
  const WalletSnapshot({
    required this.id,
    required this.balance,
    required this.updatedAt,
    required this.currency,
    this.isPlatform = false,
  });

  final String id;
  final double balance;
  final DateTime updatedAt;
  final String currency;
  final bool isPlatform;

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) => WalletSnapshot(
        id: json['id'] as String,
        balance: _parseDouble(json['balance']),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        currency: (json['currency'] as String?) ?? 'GHS',
        isPlatform: _parseBool(json['is_platform'] ?? json['isPlatform']),
      );

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  }
}

class SavingsMilestoneAchievement {
  const SavingsMilestoneAchievement({
    required this.threshold,
    required this.achievedAt,
    required this.message,
  });

  final double threshold;
  final DateTime achievedAt;
  final String message;

  factory SavingsMilestoneAchievement.fromJson(Map<String, dynamic> json) =>
      SavingsMilestoneAchievement(
        threshold: _parseDouble(json['threshold']),
        achievedAt: DateTime.parse(json['achievedAt'] as String),
        message: json['message'] as String,
      );
}

class SavingsContributionOutcome {
  const SavingsContributionOutcome({
    required this.goal,
    required this.contribution,
    this.unlockedMilestones = const [],
    this.transaction,
    this.wallet,
    this.platformWallet,
  });

  final SavingsGoalModel goal;
  final SavingsContributionModel contribution;
  final List<SavingsMilestoneAchievement> unlockedMilestones;
  final TransactionModel? transaction;
  final WalletSnapshot? wallet;
  final WalletSnapshot? platformWallet;

  factory SavingsContributionOutcome.fromJson(Map<String, dynamic> json) =>
      SavingsContributionOutcome(
        goal: SavingsGoalModel.fromApi(json['goal'] as Map<String, dynamic>),
        contribution: SavingsContributionModel.fromApi(
          json['contribution'] as Map<String, dynamic>,
        ),
        unlockedMilestones: (json['unlockedMilestones'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (milestone) =>
                  SavingsMilestoneAchievement.fromJson(milestone.cast<String, dynamic>()),
            )
            .toList(),
        transaction: json['transaction'] is Map<String, dynamic>
            ? TransactionModel.fromJson(json['transaction'] as Map<String, dynamic>)
            : null,
        wallet: json['wallet'] is Map<String, dynamic>
            ? WalletSnapshot.fromJson(json['wallet'] as Map<String, dynamic>)
            : null,
        platformWallet: json['platformWallet'] is Map<String, dynamic>
            ? WalletSnapshot.fromJson(json['platformWallet'] as Map<String, dynamic>)
            : null,
      );
}

double _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}
