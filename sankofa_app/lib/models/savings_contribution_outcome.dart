import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/models/wallet_snapshot.dart';

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
