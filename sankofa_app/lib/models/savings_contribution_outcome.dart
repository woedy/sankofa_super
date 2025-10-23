import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_goal_model.dart';

class SavingsMilestoneAchievement {
  const SavingsMilestoneAchievement({
    required this.threshold,
    required this.achievedAt,
    required this.message,
  });

  final double threshold;
  final DateTime achievedAt;
  final String message;
}

class SavingsContributionOutcome {
  const SavingsContributionOutcome({
    required this.goal,
    required this.contribution,
    this.unlockedMilestones = const [],
  });

  final SavingsGoalModel goal;
  final SavingsContributionModel contribution;
  final List<SavingsMilestoneAchievement> unlockedMilestones;
}
