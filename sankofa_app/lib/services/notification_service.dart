import 'package:sankofasave/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static const String _notificationsKey = 'notifications';

  Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey);
    if (notificationsJson != null && notificationsJson.isNotEmpty) {
      return notificationsJson.map((json) => NotificationModel.fromJson(jsonDecode(json))).toList();
    }
    final defaultNotifications = _getDefaultNotifications();
    await _saveNotifications(defaultNotifications);
    return defaultNotifications;
  }

  Future<void> _saveNotifications(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  Future<void> markAsRead(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(
        isRead: true,
        updatedAt: DateTime.now(),
      );
      await _saveNotifications(notifications);
    }
  }

  List<NotificationModel> _getDefaultNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'notif_001',
        userId: 'user_001',
        title: 'Contribution Reminder',
        message: 'Your Unity Savers Group contribution of ₵200 is due in 2 days',
        type: 'reminder',
        isRead: false,
        date: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif_002',
        userId: 'user_001',
        title: 'Payout Successful',
        message: 'You received ₵1,000 from Unity Savers Group',
        type: 'payout',
        isRead: false,
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationModel(
        id: 'notif_003',
        userId: 'user_001',
        title: 'Goal Milestone',
        message: 'You reached 80% of your Education Fund goal! Keep going!',
        type: 'achievement',
        isRead: true,
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      NotificationModel(
        id: 'notif_004',
        userId: 'user_001',
        title: 'New Member Joined',
        message: 'Abena Osei joined your Women Empowerment Circle',
        type: 'group',
        isRead: true,
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
}
