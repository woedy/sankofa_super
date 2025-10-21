import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavingsService {
  static const String _goalsKey = 'savings_goals';

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
}
