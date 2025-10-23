import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sankofasave/screens/home_screen.dart';
import 'package:sankofasave/screens/groups_screen.dart';
import 'package:sankofasave/screens/savings_screen.dart';
import 'package:sankofasave/screens/transactions_screen.dart';
import 'package:sankofasave/screens/profile_screen.dart';
import 'package:sankofasave/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NotificationService _notificationService = NotificationService();
  final PageStorageBucket _bucket = PageStorageBucket();
  late final ValueNotifier<int> _unreadNotifier;
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const GroupsScreen(),
    const SavingsScreen(),
    const TransactionsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _unreadNotifier = _notificationService.unreadCountNotifier;
    _unreadNotifications = _unreadNotifier.value;
    _unreadNotifier.addListener(_handleUnreadChange);
    _primeNotifications();
  }

  Future<void> _primeNotifications() async {
    await _notificationService.getNotifications();
  }

  void _handleUnreadChange() {
    if (!mounted) return;
    setState(() => _unreadNotifications = _unreadNotifier.value);
  }

  @override
  void dispose() {
    _unreadNotifier.removeListener(_handleUnreadChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_filled, 'Home'),
                _buildNavItem(1, Icons.groups, 'Groups'),
                _buildNavItem(2, Icons.savings, 'Savings'),
                _buildNavItem(3, Icons.receipt_long, 'Transactions'),
                _buildNavItem(4, Icons.person, 'Profile', badgeCount: _unreadNotifications),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isActive = _currentIndex == index;
    final iconColor = isActive
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex == index) return;
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
