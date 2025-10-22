import 'package:intl/intl.dart';
import 'package:sankofasave/models/notification_model.dart';
import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_contribution_outcome.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/services/notification_service.dart';
import 'package:sankofasave/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavingsService {
  static const String _goalsKey = 'savings_goals';
  static const String _contributionKeyPrefix = 'savings_goal_contributions_';
  static const List<double> _milestoneThresholds = [0.25, 0.5, 0.75];

  final TransactionService _transactionService = TransactionService();
  final NotificationService _notificationService = NotificationService();

  Future<List<SavingsGoalModel>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey);
    if (goalsJson != null && goalsJson.isNotEmpty) {
      return goalsJson.map((json) => SavingsGoalModel.fromJson(jsonDecode(json))).toList();
    }
    final defaultGoals = _getDefaultGoals();
    await _saveGoals(defaultGoals);
    return defaultGoals;
  }

  Future<SavingsGoalModel?> getGoalById(String id) async {
    final goals = await getGoals();
    try {
      return goals.firstWhere((goal) => goal.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveGoals(List<SavingsGoalModel> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = goals.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_goalsKey, goalsJson);
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    final goals = await getGoals();
    goals.add(goal);
    await _saveGoals(goals);
  }

  Future<List<SavingsContributionModel>> getContributions(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _contributionKey(goalId);
    final contributionsJson = prefs.getStringList(key);
    if (contributionsJson != null) {
      return contributionsJson
          .map((json) => SavingsContributionModel.fromJson(jsonDecode(json)))
          .toList();
    }

    final defaults = _getDefaultContributions()[goalId] ?? <SavingsContributionModel>[];
    if (defaults.isNotEmpty) {
      await _saveContributions(goalId, defaults);
    }
    return defaults;
  }

  Future<void> _saveContributions(String goalId, List<SavingsContributionModel> contributions) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _contributionKey(goalId);
    final payload = contributions.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(key, payload);
  }

  Future<SavingsContributionOutcome?> contributeToGoal({
    required String goalId,
    required double amount,
    String channel = 'Mobile Money',
    String note = 'Manual boost',
  }) async {
    if (amount <= 0) return null;

    final goals = await getGoals();
    final goalIndex = goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return null;

    final now = DateTime.now();
    final goal = goals[goalIndex];
    final previousProgress = goal.progress;
    final updatedGoal = goal.copyWith(
      currentAmount: (goal.currentAmount + amount).clamp(0, double.infinity).toDouble(),
      updatedAt: now,
    );

    goals[goalIndex] = updatedGoal;
    await _saveGoals(goals);

    final contributions = await getContributions(goalId);
    final contribution = SavingsContributionModel(
      id: 'sgc_${now.millisecondsSinceEpoch}',
      goalId: goalId,
      amount: amount,
      channel: channel,
      note: note,
      date: now,
    );

    final updatedContributions = [contribution, ...contributions];
    await _saveContributions(goalId, updatedContributions);

    await _recordContributionTransaction(
      goal: updatedGoal,
      amount: amount,
      channel: channel,
      occurredAt: now,
    );

    final unlockedMilestones = await _handleMilestones(
      goal: updatedGoal,
      previousProgress: previousProgress,
      achievedAt: now,
    );

    return SavingsContributionOutcome(
      goal: updatedGoal,
      contribution: contribution,
      unlockedMilestones: unlockedMilestones,
    );
  }

  List<SavingsGoalModel> _getDefaultGoals() {
    final now = DateTime.now();
    return [
      SavingsGoalModel(
        id: 'goal_001',
        userId: 'user_001',
        title: 'Education Fund',
        targetAmount: 5000.00,
        currentAmount: 3200.00,
        deadline: DateTime(now.year, 12, 31),
        category: 'Education',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
      SavingsGoalModel(
        id: 'goal_002',
        userId: 'user_001',
        title: 'Business Capital',
        targetAmount: 10000.00,
        currentAmount: 4500.00,
        deadline: DateTime(now.year + 1, 6, 30),
        category: 'Business',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      SavingsGoalModel(
        id: 'goal_003',
        userId: 'user_001',
        title: 'Emergency Fund',
        targetAmount: 2000.00,
        currentAmount: 1650.00,
        deadline: DateTime(now.year, now.month + 2, 15),
        category: 'Emergency',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
    ];
  }

  Map<String, List<SavingsContributionModel>> _getDefaultContributions() {
    final now = DateTime.now();
    List<SavingsContributionModel> buildEntries(String goalId, List<Map<String, Object>> entries) =>
        entries
            .map(
              (entry) => SavingsContributionModel(
                id: entry['id'] as String,
                goalId: goalId,
                amount: (entry['amount'] as num).toDouble(),
                channel: entry['channel'] as String,
                note: entry['note'] as String,
                date: now.subtract(Duration(days: entry['daysAgo'] as int)),
              ),
            )
            .toList();

    return {
      'goal_001': buildEntries('goal_001', [
        {
          'id': 'sgc_seed_001',
          'amount': 450.0,
          'channel': 'MoMo Auto-save',
          'note': 'Automated weekly top-up',
          'daysAgo': 6,
        },
        {
          'id': 'sgc_seed_002',
          'amount': 300.0,
          'channel': 'Manual Transfer',
          'note': 'Side hustle earnings',
          'daysAgo': 18,
        },
        {
          'id': 'sgc_seed_003',
          'amount': 250.0,
          'channel': 'Unity Savers Boost',
          'note': 'Group payout rollover',
          'daysAgo': 32,
        },
      ]),
      'goal_002': buildEntries('goal_002', [
        {
          'id': 'sgc_seed_004',
          'amount': 800.0,
          'channel': 'MoMo Auto-save',
          'note': 'Bi-weekly standing order',
          'daysAgo': 5,
        },
        {
          'id': 'sgc_seed_005',
          'amount': 500.0,
          'channel': 'Merchant Sales',
          'note': 'Weekend market proceeds',
          'daysAgo': 16,
        },
      ]),
      'goal_003': buildEntries('goal_003', [
        {
          'id': 'sgc_seed_006',
          'amount': 150.0,
          'channel': 'Round-up',
          'note': 'Auto round-up from wallet',
          'daysAgo': 3,
        },
        {
          'id': 'sgc_seed_007',
          'amount': 200.0,
          'channel': 'Manual Transfer',
          'note': 'Boost after payout',
          'daysAgo': 11,
        },
        {
          'id': 'sgc_seed_008',
          'amount': 180.0,
          'channel': 'Emergency Reserve',
          'note': 'Refund from medical fund',
          'daysAgo': 27,
        },
      ]),
    };
  }

  String _contributionKey(String goalId) => '$_contributionKeyPrefix$goalId';

  Future<void> _recordContributionTransaction({
    required SavingsGoalModel goal,
    required double amount,
    required String channel,
    required DateTime occurredAt,
  }) async {
    final transaction = TransactionModel(
      id: 'txn_savings_${occurredAt.millisecondsSinceEpoch}',
      userId: goal.userId,
      amount: amount,
      type: 'savings',
      status: 'success',
      description: 'Boosted ${goal.title} via $channel',
      date: occurredAt,
      createdAt: occurredAt,
      updatedAt: occurredAt,
    );

    await _transactionService.addTransaction(transaction);
  }

  Future<List<SavingsMilestoneAchievement>> _handleMilestones({
    required SavingsGoalModel goal,
    required double previousProgress,
    required DateTime achievedAt,
  }) async {
    final unlocked = <SavingsMilestoneAchievement>[];
    final currentProgress = goal.progress;

    for (final threshold in _milestoneThresholds) {
      if (previousProgress < threshold && currentProgress >= threshold) {
        final celebration = _buildMilestoneAchievement(goal, threshold, achievedAt);
        unlocked.add(celebration);
        await _notificationService.addNotification(
          _buildMilestoneNotification(goal, celebration),
        );
      }
    }

    return unlocked;
  }

  SavingsMilestoneAchievement _buildMilestoneAchievement(
    SavingsGoalModel goal,
    double threshold,
    DateTime achievedAt,
  ) {
    final percentLabel = (threshold * 100).toStringAsFixed(0);
    final formatter = NumberFormat('#,##0.00');
    final savedAmount = formatter.format(goal.targetAmount * threshold);
    final message = 'You unlocked the $percentLabel% milestone for ${goal.title}. '
        '₵$savedAmount saved so far!';

    return SavingsMilestoneAchievement(
      threshold: threshold,
      achievedAt: achievedAt,
      message: message,
    );
  }

  NotificationModel _buildMilestoneNotification(
    SavingsGoalModel goal,
    SavingsMilestoneAchievement achievement,
  ) {
    return NotificationModel(
      id: 'notif_goal_${achievement.achievedAt.millisecondsSinceEpoch}_${goal.id}',
      userId: goal.userId,
      title: 'Savings milestone unlocked',
      message: achievement.message,
      type: 'achievement',
      isRead: false,
      date: achievement.achievedAt,
      createdAt: achievement.achievedAt,
      updatedAt: achievement.achievedAt,
    );
  }
}
