import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/controllers/theme_controller.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/screens/dispute_center_screen.dart';
import 'package:sankofasave/screens/splash_screen.dart';
import 'package:sankofasave/screens/support_center_screen.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/ui/components/info_card.dart';
import 'package:sankofasave/ui/components/section_header.dart';
import 'package:sankofasave/widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _user;
  bool _transactionAlerts = true;
  bool _goalReminders = true;
  bool _biometricLogin = true;
  bool _twoFactorEnabled = true;
  String _preferredLanguage = 'English';

  final List<String> _languageOptions = const ['English', 'Twi', 'Ga', 'Ewe'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getCurrentUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = ThemeControllerProvider.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildProfileHero(themeController),
                    ),
                    const SizedBox(height: 32),
                    const SectionHeader(
                      title: 'Personal',
                      subtitle: 'Keep your contact details and identification up to date.',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCard(
                        title: 'Personal information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoRow(label: 'Full name', value: _user!.name),
                            InfoRow(label: 'Phone number', value: _user!.phone),
                            InfoRow(label: 'Email address', value: _user!.email),
                            InfoRow(
                              label: 'Member since',
                              value: DateFormat.yMMMMd().format(_user!.createdAt),
                            ),
                            InfoRow(label: 'Customer ID', value: _user!.id),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showSnack('Profile editing is coming soon.'),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit profile'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showSnack('We\'ll let you update mobile money details shortly.'),
                                  icon: const Icon(Icons.phone_iphone),
                                  label: const Text('Manage MoMo account'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'Security',
                      subtitle: 'Control sign-in, approvals, and trusted device settings.',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCard(
                        title: 'Security controls',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile.adaptive(
                              value: _twoFactorEnabled,
                              onChanged: (value) {
                                setState(() => _twoFactorEnabled = value);
                                _showSnack(value
                                    ? 'Two-step verification reminders enabled.'
                                    : 'Two-step verification reminders paused.');
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: _buildIconBadge(Icons.verified_user),
                              title: const Text('Two-step verification'),
                              subtitle: const Text('Approve new devices with a quick confirmation.'),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Divider(height: 24),
                            SwitchListTile.adaptive(
                              value: _biometricLogin,
                              onChanged: (value) {
                                setState(() => _biometricLogin = value);
                                _showSnack(value
                                    ? 'Biometric sign-in enabled on this device.'
                                    : 'Biometric sign-in disabled.');
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: _buildIconBadge(Icons.fingerprint),
                              title: const Text('Biometric sign-in'),
                              subtitle: const Text('Use Face ID or fingerprint for faster access.'),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Divider(height: 24),
                            _settingTile(
                              icon: Icons.phonelink_lock,
                              title: 'Trusted devices',
                              subtitle: 'Review where you\'re signed in and revoke access.',
                              onTap: () =>
                                  _showSnack('Device management will arrive in the next sprint.'),
                            ),
                            const Divider(height: 24),
                            _settingTile(
                              icon: Icons.shield_moon_outlined,
                              title: 'Session timeout',
                              subtitle: 'We\'ll auto-lock after 10 minutes of inactivity.',
                              trailing: Chip(
                                label: const Text('10 min'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'Preferences',
                      subtitle: 'Choose how SankoFa Save looks and keeps you informed.',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCard(
                        title: 'Experience & notifications',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile.adaptive(
                              value: themeController.themeMode == ThemeMode.dark,
                              onChanged: (value) {
                                themeController
                                    .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                                _showSnack(value ? 'Dark mode enabled.' : 'Light mode enabled.');
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: _buildIconBadge(
                                themeController.themeMode == ThemeMode.dark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                              ),
                              title: const Text('Appearance'),
                              subtitle: const Text('Switch between light and dark experiences.'),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Divider(height: 24),
                            SwitchListTile.adaptive(
                              value: _transactionAlerts,
                              onChanged: (value) {
                                setState(() => _transactionAlerts = value);
                                _showSnack(value
                                    ? 'Transaction alerts will stay on.'
                                    : 'Transaction alerts paused.');
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: _buildIconBadge(Icons.notifications_active_outlined),
                              title: const Text('Real-time transaction alerts'),
                              subtitle: const Text(
                                  'Get push notifications as deposits or withdrawals clear.'),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Divider(height: 24),
                            SwitchListTile.adaptive(
                              value: _goalReminders,
                              onChanged: (value) {
                                setState(() => _goalReminders = value);
                                _showSnack(value
                                    ? 'Savings goal nudges enabled.'
                                    : 'Savings reminders muted for now.');
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: _buildIconBadge(Icons.flag_outlined),
                              title: const Text('Savings goal nudges'),
                              subtitle:
                                  const Text('Stay on track with friendly milestone reminders.'),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Language',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _preferredLanguage,
                              items: _languageOptions
                                  .map(
                                    (language) => DropdownMenuItem<String>(
                                      value: language,
                                      child: Text(language),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _preferredLanguage = value);
                                _showSnack('Language set to $value.');
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                                labelText: 'Preferred language',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'Account',
                      subtitle: 'Download statements or update support preferences.',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCard(
                        title: 'Account tools',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _settingTile(
                              icon: Icons.receipt_long,
                              title: 'Statements & receipts',
                              subtitle:
                                  'Download a snapshot of your recent deposits and withdrawals.',
                              onTap: () =>
                                  _showSnack('Cashflow receipts will ship with the export update.'),
                            ),
                            const Divider(height: 24),
                            _settingTile(
                              icon: Icons.forum_outlined,
                              title: 'Disputes',
                              subtitle: 'Report an issue or track existing cases with support.',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const DisputeCenterScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 24),
                            _settingTile(
                              icon: Icons.support_agent,
                              title: 'Support center',
                              subtitle: 'Chat with us or browse upcoming FAQ topics.',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SupportCenterScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => _buildLogoutDialog(),
                                );
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Log out of SankoFa Save'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHero(ThemeController themeController) {
    final user = _user!;
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: 'GH₵', decimalDigits: 2);
    final balanceLabel = currencyFormatter.format(user.walletBalance);
    final memberSince = DateFormat('MMM yyyy').format(user.createdAt);
    final isDark = theme.brightness == Brightness.dark;
    final Color startColor = isDark ? theme.colorScheme.primaryContainer : theme.colorScheme.primary;
    final Color endColor = isDark ? theme.colorScheme.tertiary : theme.colorScheme.secondary;
    final Color textColor =
        isDark ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                initials: user.name.substring(0, 1).toUpperCase(),
                imagePath: user.photoUrl,
                size: 72,
                borderColor: textColor.withOpacity(0.4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor.withOpacity(0.75),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor.withOpacity(0.75),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showSnack('Profile photo updates will land soon.'),
                icon: Icon(Icons.edit_outlined, color: textColor),
                tooltip: 'Update photo',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroChip(Icons.verified_user, 'KYC verified', textColor),
              _buildHeroChip(Icons.calendar_month, 'Member since $memberSince', textColor),
              _buildHeroChip(Icons.account_balance_wallet_outlined, balanceLabel, textColor),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showSnack('Profile editing is coming soon.'),
                icon: Icon(Icons.tune, color: textColor),
                label: Text(
                  'Profile preferences',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: textColor.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await themeController.toggleTheme();
                  _showSnack('Theme updated.');
                },
                icon: Icon(Icons.sync, color: textColor),
                label: Text(
                  'Flip theme',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.14),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildIconBadge(IconData icon) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: _buildIconBadge(icon),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.2)),
    );
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await _userService.clearSession();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

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
            onPressed: () async => _handleLogout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      );

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
