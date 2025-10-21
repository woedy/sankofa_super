import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/notification_model.dart';
import 'package:sankofasave/services/notification_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationService.getNotifications();
    setState(() => _notifications = notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Color(0xFF0F172A))),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty
            ? const Center(child: Text('No notifications'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await _notificationService.markAsRead(notification.id);
                        setState(() => _notifications.removeAt(index));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification dismissed')),
                          );
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: _buildNotificationCard(notification),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final theme = Theme.of(context);
    final accent = _getNotificationColor(notification.type);

    return NotificationCard(
      icon: _getNotificationIcon(notification.type),
      title: notification.title,
      message: notification.message,
      timestamp: DateFormat('MMM dd, yyyy • hh:mm a').format(notification.date),
      isRead: notification.isRead,
      accentColor: accent,
      onTap: () async {
        if (!notification.isRead) {
          await _notificationService.markAsRead(notification.id);
          _loadNotifications();
        }
      },
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'reminder':
        return Icons.alarm;
      case 'payout':
        return Icons.account_balance_wallet;
      case 'achievement':
        return Icons.emoji_events;
      case 'group':
        return Icons.groups;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'reminder':
        return const Color(0xFF0891B2);
      case 'payout':
        return const Color(0xFF14B8A6);
      case 'achievement':
        return const Color(0xFFF59E0B);
      case 'group':
        return const Color(0xFF1E3A8A);
      default:
        return Colors.grey;
    }
  }
}
