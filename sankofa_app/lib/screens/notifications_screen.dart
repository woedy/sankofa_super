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
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationService.getNotifications();
    notifications.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() => _notifications = notifications);
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll || !_notifications.any((n) => !n.isRead)) return;
    setState(() => _isMarkingAll = true);
    await _notificationService.markAllAsRead();
    await _loadNotifications();
    if (mounted) {
      setState(() => _isMarkingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((notification) => !notification.isRead).length;
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
        actions: [
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: unreadCount == 0 || _isMarkingAll ? null : _markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: unreadCount == 0 || _isMarkingAll
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 160),
                  Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'You’re all caught up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'We’ll nudge you here when there’s activity on your susu goals and groups.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(height: 200),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 32),
                children: _buildNotificationSections(),
              ),
      ),
    );
  }

  List<Widget> _buildNotificationSections() {
    final now = DateTime.now();
    final today = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (final notification in _notifications) {
      if (_isSameDay(notification.date, now)) {
        today.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    final children = <Widget>[];

    if (today.isNotEmpty) {
      children
        ..add(_buildSectionHeader('Today'))
        ..addAll(today.map(_buildNotificationTile));
    }

    if (earlier.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 20));
      }
      children
        ..add(_buildSectionHeader('Earlier'))
        ..addAll(earlier.map(_buildNotificationTile));
    }

    return children;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          await _notificationService.markAsRead(notification.id);
          setState(() => _notifications.removeWhere((n) => n.id == notification.id));
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
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
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
      case 'wallet':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
