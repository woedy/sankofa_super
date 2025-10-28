import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/controllers/theme_controller.dart';
import 'package:sankofasave/data/process_flows.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/models/process_flow_model.dart';
import 'package:sankofasave/screens/deposit_flow_screen.dart';
import 'package:sankofasave/screens/withdrawal_flow_screen.dart';
import 'package:sankofasave/screens/group_creation_wizard_screen.dart';
import 'package:sankofasave/screens/group_join_wizard_screen.dart';
import 'package:sankofasave/screens/notifications_screen.dart';
import 'package:sankofasave/screens/process_flow_screen.dart';
import 'package:sankofasave/screens/savings_goal_wizard_screen.dart';
import 'package:sankofasave/screens/transaction_detail_modal.dart';
import 'package:sankofasave/screens/transactions_screen.dart';
import 'package:sankofasave/services/transaction_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/widgets/user_avatar.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final TransactionService _transactionService = TransactionService();
  UserModel? _user;
  List<TransactionModel> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    final transactions = await _transactionService.getTransactions();
    setState(() {
      _user = user;
      _recentTransactions = transactions.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                elevation: 0,
                pinned: true,
                toolbarHeight: 96,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      UserAvatar(
                        initials: _user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        imagePath: _user?.photoUrl,
                        size: 48,
                        borderColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hello, ${_user?.name.split(' ').first ?? 'User'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('🇬🇭', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Akwaaba back to your Susu hub',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderActionButton(
                        icon: Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        onTap: () => ThemeControllerProvider.of(context).toggleTheme(),
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderActionButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => Navigator.of(context).push(
                          RouteTransitions.slideLeft(const NotificationsScreen()),
                        ),
                        showIndicator: _recentTransactions.any((t) => t.status != 'success'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildWalletCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildProcessFlowsSection(),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final user = _user;
    final theme = Theme.of(context);
    final balance = user?.walletBalance ?? 0;
    final requiresKyc = user?.requiresKyc ?? true;
    final isVerified = user?.isKycApproved ?? false;
    final isInReview = (user?.isKycInReview ?? false) && !requiresKyc;
    final statusLabel = user == null
        ? '—'
        : isVerified
            ? 'Verified'
            : isInReview
                ? 'In Review'
                : 'KYC Required';
    final statusIcon = isVerified
        ? Icons.verified_user
        : isInReview
            ? Icons.hourglass_top
            : Icons.lock_clock;
    final statusBackground = isVerified
        ? Colors.white.withValues(alpha: 0.22)
        : isInReview
            ? theme.colorScheme.secondary.withValues(alpha: 0.18)
            : theme.colorScheme.error.withValues(alpha: 0.18);
    final statusForeground = isVerified
        ? Colors.white
        : isInReview
            ? theme.colorScheme.onSecondary
            : theme.colorScheme.error;
    final updatedLabel = user == null
        ? '—'
        : DateFormat('MMM d • h:mm a')
            .format(user.walletUpdatedAt ?? user.updatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: WalletSummaryCard(
        title: 'Wallet Balance',
        value: 'GH₵ ${NumberFormat('#,##0.00').format(balance)}',
        status: WalletSummaryStatus(
          label: statusLabel,
          icon: statusIcon,
          backgroundColor: statusBackground,
          foregroundColor: statusForeground,
        ),
        primaryActionLabel: 'Add Funds',
        onPrimaryAction: () => _openProcess(ProcessFlows.deposit),
        trailing: user == null ? null : _buildWalletInfoPanel(user, updatedLabel),
        gradientColors: (!requiresKyc)
            ? [theme.colorScheme.primary, theme.colorScheme.secondary]
            : [theme.colorScheme.primaryContainer, theme.colorScheme.primary],
      ),
    );
  }

  Widget _buildWalletInfoPanel(UserModel user, String updatedLabel) {
    final deviceSize = ResponsiveBreakpoints.of(context);
    final isCompact = deviceSize == DeviceSize.small;

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWalletHighlight(Icons.phone_iphone, 'Primary MoMo', user.phone),
            const SizedBox(height: 12),
            _buildWalletHighlight(Icons.schedule, 'Last Activity', updatedLabel),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _buildWalletHighlight(Icons.phone_iphone, 'Primary MoMo', user.phone),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _buildWalletHighlight(Icons.schedule, 'Last Activity', updatedLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHighlight(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: const BoxConstraints(minWidth: 140, minHeight: 78),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final deviceSize = ResponsiveBreakpoints.of(context);
            final isCompact = deviceSize == DeviceSize.small;
            final spacing = isCompact ? 12.0 : 16.0;
            final availableWidth = constraints.maxWidth;
            final tileWidth = isCompact
                ? availableWidth
                : (availableWidth - spacing) / 2;

            final actions = <_QuickActionItem>[
              _QuickActionItem(
                label: 'Deposit',
                icon: Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.secondary,
                onTap: _launchDepositFlow,
              ),
              _QuickActionItem(
                label: 'Withdraw',
                icon: Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                onTap: _launchWithdrawalFlow,
              ),
              _QuickActionItem(
                label: 'Join Public Group',
                icon: Icons.group_add_outlined,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: _launchGroupJoin,
              ),
              _QuickActionItem(
                label: 'Create Private Group',
                icon: Icons.lock_person_outlined,
                color: Theme.of(context).colorScheme.primaryContainer,
                onTap: _launchGroupCreation,
              ),
              _QuickActionItem(
                label: 'New Savings Goal',
                icon: Icons.flag_circle_outlined,
                color: Theme.of(context).colorScheme.secondaryContainer,
                onTap: _launchGoalCreation,
              ),
              _QuickActionItem(
                label: 'Boost Savings',
                icon: Icons.savings_outlined,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _openProcess(ProcessFlows.savings),
              ),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: actions
                      .map(
                        (action) => SizedBox(
                          width: isCompact ? availableWidth : tileWidth,
                          child: _buildActionButton(
                            action.label,
                            action.icon,
                            action.color,
                            action.onTap,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      );

  Widget _buildProcessFlowsSection() {
    final flows = [
      ProcessFlows.deposit,
      ProcessFlows.withdrawal,
      ProcessFlows.joinGroup,
      ProcessFlows.createGroup,
      ProcessFlows.savings,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Process Demos',
            actionLabel: 'Open Deposit Demo',
            onAction: () => _openProcess(ProcessFlows.deposit),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 228,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final flow = flows[index];
                return _ProcessFlowCard(
                  flow: flow,
                  onTap: () => _openProcess(flow),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: flows.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.09),
                color.withValues(alpha: 0.22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right, size: 18, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showIndicator = false,
  }) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
          ),
        ),
        if (showIndicator)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildRecentTransactions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Transactions',
          actionLabel: 'See All',
          onAction: () => Navigator.of(context).push(
            RouteTransitions.slideLeft(const TransactionsScreen()),
          ),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              'No transactions yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < _recentTransactions.length; i++) ...[
                _buildTransactionTile(_recentTransactions[i]),
                if (i != _recentTransactions.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    ),
  );

  Widget _buildTransactionTile(TransactionModel transaction) {
    final color = _getTransactionColor(transaction.type);
    final theme = Theme.of(context);
    final isPositive = transaction.type == 'deposit' || transaction.type == 'payout';
    final amountPrefix = isPositive ? '+' : '-';
    final statusColor = transaction.status == 'success'
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;

    return GestureDetector(
      onTap: () => showTransactionDetailModal(context, transaction),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getTransactionIcon(transaction.type), color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(transaction.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${amountPrefix}GH₵ ${NumberFormat('#,##0.00').format(transaction.amount)}',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isPositive ? theme.colorScheme.secondary : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    transaction.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('hh:mm a').format(transaction.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icons.add_circle;
      case 'withdrawal':
        return Icons.remove_circle;
      case 'contribution':
        return Icons.group;
      case 'payout':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.payment;
    }
  }

  Future<void> _launchDepositFlow() async {
    final result = await Navigator.of(context).push<bool>(
      RouteTransitions.slideUp(const DepositFlowScreen()),
    );
    if (result == true) {
      await _loadData();
      _showSnackBar('Deposit recorded and wallet updated.');
    }
  }

  Future<void> _launchWithdrawalFlow() async {
    final result = await Navigator.of(context).push<WithdrawalSubmissionStatus>(
      RouteTransitions.slideUp(const WithdrawalFlowScreen()),
    );
    if (result != null) {
      await _loadData();
      if (!mounted) return;
      final message = switch (result) {
        WithdrawalSubmissionStatus.success =>
            'Withdrawal request submitted. Watch for the confirmation shortly.',
        WithdrawalSubmissionStatus.pending =>
            'Withdrawal queued for review. We\'ll update you when it clears.',
        WithdrawalSubmissionStatus.failed =>
            'Withdrawal flagged for follow-up. Check notifications for next steps.',
      };
      _showSnackBar(message);
    }
  }

  Future<void> _launchGroupCreation() async {
    final createdGroup = await Navigator.of(context).push<SusuGroupModel>(
      RouteTransitions.slideUp(const GroupCreationWizardScreen()),
    );
    if (createdGroup == null) return;

    _showSnackBar(
      '${createdGroup.name} is ready with ${createdGroup.memberNames.length} members.',
    );
  }

  Future<void> _launchGroupJoin() async {
    final joinedGroup = await Navigator.of(context).push<SusuGroupModel>(
      RouteTransitions.slideUp(const GroupJoinWizardScreen()),
    );
    if (joinedGroup == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome to ${joinedGroup.name}!'),
      ),
    );
  }

  Future<void> _launchGoalCreation() async {
    final createdGoal = await Navigator.of(context).push<SavingsGoalModel>(
      RouteTransitions.slideUp(const SavingsGoalWizardScreen()),
    );
    if (createdGoal == null) return;

    _showSnackBar('New goal “${createdGoal.title}” is ready to start growing.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openProcess(ProcessFlowModel flow) {
    Navigator.of(context).push(
      RouteTransitions.slideUp(ProcessFlowScreen(flow: flow)),
    );
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'deposit':
        return const Color(0xFF14B8A6);
      case 'withdrawal':
        return const Color(0xFF1E3A8A);
      case 'contribution':
        return const Color(0xFF0891B2);
      case 'payout':
        return const Color(0xFF14B8A6);
      case 'savings':
        return const Color(0xFF1E3A8A);
      default:
        return Colors.grey;
    }
  }
}

class _ProcessFlowCard extends StatelessWidget {
  const _ProcessFlowCard({required this.flow, required this.onTap});

  final ProcessFlowModel flow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 300,
      child: EntityListTile(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        leading: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                flow.heroAsset,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            _buildMeta(theme, Icons.stacked_line_chart, '${flow.steps.length} steps'),
          ],
        ),
        title: Text(
          flow.title,
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flow.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _buildMeta(theme, Icons.timer_outlined, flow.expectation),
          ],
        ),
        meta: const [],
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }

  Widget _buildMeta(ThemeData theme, IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
}

