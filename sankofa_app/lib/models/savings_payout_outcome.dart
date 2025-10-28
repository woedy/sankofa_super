import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/savings_redemption_model.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/models/wallet_snapshot.dart';

class SavingsPayoutOutcome {
  const SavingsPayoutOutcome({
    required this.goal,
    required this.redemption,
    this.transaction,
    this.wallet,
    this.platformWallet,
  });

  final SavingsGoalModel goal;
  final SavingsRedemptionModel redemption;
  final TransactionModel? transaction;
  final WalletSnapshot? wallet;
  final WalletSnapshot? platformWallet;

  factory SavingsPayoutOutcome.fromJson(Map<String, dynamic> json) => SavingsPayoutOutcome(
        goal: SavingsGoalModel.fromApi(json['goal'] as Map<String, dynamic>),
        redemption: SavingsRedemptionModel.fromApi(json['redemption'] as Map<String, dynamic>),
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
