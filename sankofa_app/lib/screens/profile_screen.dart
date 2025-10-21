import 'package:flutter/material.dart';
import 'package:sankofasave/controllers/theme_controller.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/screens/splash_screen.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getCurrentUser();
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      UserAvatar(
                        initials: _user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        imagePath: _user?.photoUrl,
                        size: 100,
                        borderColor: Theme.of(context).colorScheme.secondary,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.background, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.name ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KYC Verified',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildMenuItem(Icons.person_outline, 'Account Details', () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.phone_android, 'Linked Mobile Money', () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.security, 'Security & 2FA', () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.notifications_outlined, 'Notification Settings', () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.language, 'Language', () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.help_outline, 'Help & Support', () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.info_outline, 'About', () {}),
                  const Divider(height: 1),
                  _buildThemeMenu(context),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildMenuItem(
                Icons.logout,
                'Logout',
                () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildLogoutDialog(),
                  );
                },
                textColor: Colors.red,
                iconColor: Colors.red,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
    Color? iconColor,
  }) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
    title: Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
    ),
    trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
  );

  Widget _buildLogoutDialog() => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Logout'),
    content: const Text('Are you sure you want to logout?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Logout'),
      ),
    ],
  );

  Widget _buildThemeMenu(BuildContext context) {
    final themeController = ThemeControllerProvider.of(context);
    final isDarkMode = themeController.themeMode == ThemeMode.dark;
    return SwitchListTile.adaptive(
      value: isDarkMode,
      onChanged: (value) => themeController.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: Icon(
        isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(
        'Dark Mode',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Switch between light and dark experiences',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}
