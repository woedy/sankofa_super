import 'dart:convert';

import 'package:sankofasave/models/notification_model.dart';
import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_contribution_outcome.dart';
import 'package:sankofasave/models/savings_goal_draft_model.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/savings_payout_outcome.dart';
import 'package:sankofasave/services/notification_service.dart';
import 'package:sankofasave/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'user_service.dart';

class SavingsService {
  SavingsService({
    ApiClient? apiClient,
    NotificationService? notificationService,
    TransactionService? transactionService,
    UserService? userService,
  }) : this._(
          apiClient: apiClient ?? ApiClient(),
          notificationService: notificationService,
          transactionService: transactionService,
          userService: userService,
        );

  SavingsService._({
    required ApiClient apiClient,
    NotificationService? notificationService,
    TransactionService? transactionService,
    UserService? userService,
  })  : _apiClient = apiClient,
        _notificationService = notificationService ?? NotificationService(),
        _transactionService = transactionService ?? TransactionService(apiClient: apiClient),
        _userService = userService ?? UserService(apiClient: apiClient);

  final ApiClient _apiClient;
  final NotificationService _notificationService;
  final TransactionService _transactionService;
  final UserService _userService;

  static const String _draftKey = 'savings_goal_draft';

  List<SavingsGoalModel>? _cachedGoals;

  Future<List<SavingsGoalModel>> getGoals({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGoals != null) {
      return _cachedGoals!;
    }

    try {
      final response = await _apiClient.get('/api/savings/goals/');
      if (response is List) {
        final goals = response
            .whereType<Map>()
            .map((item) => SavingsGoalModel.fromApi(item.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _cachedGoals = goals;
        return goals;
      }
    } catch (_) {
      // swallow API errors so offline data can continue to display
    }

    _cachedGoals ??= const [];
    return _cachedGoals!;
  }

  Future<SavingsGoalModel?> getGoalById(String id) async {
    final cached = _cachedGoals;
    if (cached != null) {
      try {
        return cached.firstWhere((goal) => goal.id == id);
      } catch (_) {
        // continue to fetch from API
      }
    }

    try {
      final response = await _apiClient.get('/api/savings/goals/$id/');
      if (response is Map<String, dynamic>) {
        final goal = SavingsGoalModel.fromApi(response);
        _upsertCachedGoal(goal);
        return goal;
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  Future<SavingsGoalModel> createGoalFromDraft(SavingsGoalDraftModel draft) async {
    if (draft.title == null || draft.title!.trim().isEmpty) {
      throw StateError('Goal title missing');
    }
    if (draft.targetAmount == null || draft.targetAmount! <= 0) {
      throw StateError('Target amount missing');
    }
    if (draft.deadline == null) {
      throw StateError('Deadline missing');
    }
    if (draft.category == null || draft.category!.trim().isEmpty) {
      throw StateError('Category missing');
    }

    final payload = {
      'title': draft.title!.trim(),
      'targetAmount': draft.targetAmount,
      'deadline': draft.deadline!.toIso8601String(),
      'category': draft.category!.trim(),
    };

    final response = await _apiClient.post('/api/savings/goals/', body: payload);
    if (response is Map<String, dynamic>) {
      final goal = SavingsGoalModel.fromApi(response);
      _upsertCachedGoal(goal, prepend: true);
      await clearDraftGoal();
      return goal;
    }
    throw StateError('Unexpected response when creating savings goal');
  }

  Future<List<SavingsContributionModel>> getContributions(String goalId) async {
    try {
      final response = await _apiClient.get('/api/savings/goals/$goalId/contributions/');
      if (response is List) {
        return response
            .whereType<Map>()
            .map((item) => SavingsContributionModel.fromApi(item.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {
      // ignore errors so UI can fallback to empty list
    }
    return const [];
  }

  Future<SavingsContributionOutcome?> contributeToGoal({
    required String goalId,
    required double amount,
    String channel = 'Mobile Money',
    String note = '',
  }) async {
    if (amount <= 0) return null;

    final payload = {
      'amount': amount,
      if (channel.isNotEmpty) 'channel': channel,
      'note': note,
    };

    try {
      final response = await _apiClient.post(
        '/api/savings/goals/$goalId/contributions/',
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final outcome = SavingsContributionOutcome.fromJson(response);
        _upsertCachedGoal(outcome.goal);
        await _recordMilestoneNotifications(outcome);
        if (outcome.transaction != null) {
          _transactionService.recordRemoteTransaction(outcome.transaction!);
        }
        if (outcome.wallet != null) {
          await _userService.updateWalletBalance(
            outcome.wallet!.balance,
            walletUpdatedAt: outcome.wallet!.updatedAt,
          );
        }
        return outcome;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<SavingsPayoutOutcome?> collectFromGoal({
    required String goalId,
    required double amount,
    String channel = 'Wallet payout',
    String note = '',
  }) async {
    if (amount <= 0) return null;

    final payload = {
      'amount': amount,
      if (channel.isNotEmpty) 'channel': channel,
      'note': note,
    };

    try {
      final response = await _apiClient.post(
        '/api/savings/goals/$goalId/collect/',
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final outcome = SavingsPayoutOutcome.fromJson(response);
        _upsertCachedGoal(outcome.goal);
        if (outcome.transaction != null) {
          _transactionService.recordRemoteTransaction(outcome.transaction!);
        }
        if (outcome.wallet != null) {
          await _userService.updateWalletBalance(
            outcome.wallet!.balance,
            walletUpdatedAt: outcome.wallet!.updatedAt,
          );
        }
        return outcome;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<SavingsGoalDraftModel?> getDraftGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(draftJson) as Map<String, dynamic>;
      return SavingsGoalDraftModel.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_draftKey);
      return null;
    }
  }

  Future<void> saveDraftGoal(SavingsGoalDraftModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearDraftGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _upsertCachedGoal(SavingsGoalModel goal, {bool prepend = false}) {
    final current = List<SavingsGoalModel>.from(_cachedGoals ?? const []);
    final index = current.indexWhere((item) => item.id == goal.id);
    if (index >= 0) {
      current[index] = goal;
    } else {
      if (prepend) {
        current.insert(0, goal);
      } else {
        current.add(goal);
      }
    }
    current.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _cachedGoals = current;
  }

  Future<void> _recordMilestoneNotifications(SavingsContributionOutcome outcome) async {
    if (outcome.unlockedMilestones.isEmpty) {
      return;
    }

    final goal = outcome.goal;
    for (final milestone in outcome.unlockedMilestones) {
      final notification = NotificationModel(
        id: 'notif_goal_${goal.id}_${milestone.achievedAt.millisecondsSinceEpoch}',
        userId: goal.userId,
        title: 'Savings milestone unlocked',
        message: milestone.message,
        type: 'achievement',
        isRead: false,
        date: milestone.achievedAt,
        createdAt: milestone.achievedAt,
        updatedAt: milestone.achievedAt,
      );
      await _notificationService.addNotification(notification);
    }
  }
}
