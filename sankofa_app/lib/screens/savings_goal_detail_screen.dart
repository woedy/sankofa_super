import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_contribution_outcome.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/models/savings_payout_outcome.dart';
import 'package:sankofasave/services/savings_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

class SavingsGoalDetailScreen extends StatefulWidget {
  const SavingsGoalDetailScreen({super.key, required this.goal});

  final SavingsGoalModel goal;

  @override
  State<SavingsGoalDetailScreen> createState() => _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  late SavingsGoalModel _goal;
  final SavingsService _savingsService = SavingsService();
  final List<SavingsContributionModel> _contributions = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _collectAmountController = TextEditingController();
  final TextEditingController _collectNoteController = TextEditingController();
  final GlobalKey<FormState> _collectFormKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');
  bool _isLoadingContributions = true;
  bool _isSubmitting = false;
  bool _isCollecting = false;
  bool _hasChanges = false;
  final Map<double, DateTime> _milestoneHistory = {};

  static const List<double> _milestoneThresholds = [0.25, 0.5, 0.75];

  static const double _minBoostAmount = 50.0;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadContributions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _collectAmountController.dispose();
    _collectNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadContributions() async {
    final contributions = await _savingsService.getContributions(_goal.id);
    if (!mounted) return;
    setState(() {
      _contributions
        ..clear()
        ..addAll(contributions);
      _isLoadingContributions = false;
      _recalculateMilestones();
    });
  }

  double get _remainingAmount => (_goal.targetAmount - _goal.currentAmount).clamp(0, double.infinity);
  double get _availableToCollect => _goal.currentAmount.clamp(0, double.infinity);

  Future<void> _submitBoost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    setState(() => _isSubmitting = true);

    final outcome = await _savingsService.contributeToGoal(
      goalId: _goal.id,
      amount: amount,
      note: note.isEmpty ? 'Manual boost' : note,
      channel: 'Manual boost',
    );

    final contributions = await _savingsService.getContributions(_goal.id);

    if (!mounted) {
      return;
    }

    setState(() {
      if (outcome != null) {
        _goal = outcome.goal;
        _hasChanges = true;
      }
      _contributions
        ..clear()
        ..addAll(contributions);
      _isSubmitting = false;
      _amountController.clear();
      _noteController.clear();
      _recalculateMilestones();
    });

    if (outcome != null && mounted) {
      final progress = (_goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
      final List<SavingsMilestoneAchievement> unlocked = outcome.unlockedMilestones;
      if (unlocked.isNotEmpty) {
        final celebration = unlocked.first;
        final milestoneLabel = (celebration.threshold * 100).toStringAsFixed(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Milestone unlocked! $milestoneLabel% of ${_goal.title} saved.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Boost added! You are now $progress% to your goal.'),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to record boost. Please try again.')),
      );
    }
  }

  Future<void> _submitCollection() async {
    if (!_collectFormKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_collectAmountController.text.trim());
    final note = _collectNoteController.text.trim();

    setState(() => _isCollecting = true);

    final SavingsPayoutOutcome? outcome = await _savingsService.collectFromGoal(
      goalId: _goal.id,
      amount: amount,
      note: note.isEmpty ? 'Savings payout' : note,
      channel: 'Wallet payout',
    );

    final contributions = await _savingsService.getContributions(_goal.id);

    if (!mounted) {
      return;
    }

    setState(() {
      if (outcome != null) {
        _goal = outcome.goal;
        _hasChanges = true;
      }
      _contributions
        ..clear()
        ..addAll(contributions);
      _isCollecting = false;
      _collectAmountController.clear();
      _collectNoteController.clear();
      _recalculateMilestones();
    });

    if (outcome != null && mounted) {
      final formattedAmount = _currencyFormatter.format(amount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GH₵ $formattedAmount moved back to your wallet.')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to collect savings. Please try again.')),
      );
    }
  }

  void _handleBack() {
    if (_hasChanges) {
      Navigator.pop(context, _goal);
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool> _handleWillPop() async {
    if (_hasChanges) {
      Navigator.pop(context, _goal);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Savings Goal'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _buildHeroCard(theme),
              const SizedBox(height: 24),
              _buildFinancialOverview(theme),
              const SizedBox(height: 24),
              _buildAutomationPlan(theme),
              const SizedBox(height: 24),
              _buildContributionHistory(theme),
              const SizedBox(height: 24),
              _buildBoostForm(theme),
              const SizedBox(height: 24),
              _buildCollectForm(theme),
              const SizedBox(height: 24),
              _buildMilestones(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectForm(ThemeData theme) {
    final available = _availableToCollect;
    final hasBalance = available > 0;
    return InfoCard(
      title: 'Collect Savings',
      child: Form(
        key: _collectFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasBalance
                  ? 'Move part of your saved balance back into your wallet. Available now: GH₵ ${_currencyFormatter.format(available)}.'
                  : 'Once you have a saved balance you can move funds back to your wallet from here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _collectAmountController,
              enabled: hasBalance && !_isCollecting,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount to collect (GH₵)',
                hintText: hasBalance ? _currencyFormatter.format(available) : '0.00',
                prefixIcon: const Icon(Icons.wallet_rounded),
              ),
              validator: (value) {
                if (!hasBalance) {
                  return 'No savings available just yet';
                }
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Enter an amount to move back to your wallet.';
                }
                final parsed = double.tryParse(trimmed);
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                if (parsed <= 0) {
                  return 'Amount must be greater than zero';
                }
                if (parsed > available + 0.001) {
                  return 'You only have GH₵ ${_currencyFormatter.format(available)} available.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _collectNoteController,
              enabled: hasBalance && !_isCollecting,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'Explain why you’re collecting these funds',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: !hasBalance || _isCollecting ? null : _submitCollection,
              icon: _isCollecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.savings_outlined),
              label: Text(_isCollecting ? 'Processing...' : 'Collect savings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final percentage = (_goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _goal.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _goal.category,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _goal.progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percentage% complete',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                'Due ${DateFormat('dd MMM yyyy').format(_goal.deadline)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(ThemeData theme) {
    final remaining = _remainingAmount;
    return InfoCard(
      title: 'Financial Overview',
      child: Column(
        children: [
          InfoRow(label: 'Target', value: 'GH₵ ${_currencyFormatter.format(_goal.targetAmount)}'),
          InfoRow(label: 'Saved so far', value: 'GH₵ ${_currencyFormatter.format(_goal.currentAmount)}'),
          InfoRow(label: 'Remaining', value: 'GH₵ ${_currencyFormatter.format(remaining)}'),
          InfoRow(label: 'Start Date', value: DateFormat('dd MMM yyyy').format(_goal.createdAt)),
          InfoRow(label: 'Last Updated', value: DateFormat('dd MMM yyyy').format(_goal.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildAutomationPlan(ThemeData theme) {
    return InfoCard(
      title: 'Automation Plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem(
            theme,
            icon: Icons.calendar_month_outlined,
            title: 'Weekly top-up scheduled',
            subtitle: 'GH₵ ${(_goal.targetAmount / 26).toStringAsFixed(2)} auto-debits every Monday',
          ),
          const SizedBox(height: 12),
          _buildChecklistItem(
            theme,
            icon: Icons.link_outlined,
            title: 'Linked to Unity Savers payout',
            subtitle: '10% of group payout nudged into this goal automatically',
          ),
          const SizedBox(height: 12),
          _buildChecklistItem(
            theme,
            icon: Icons.shield_moon_outlined,
            title: 'Safety net active',
            subtitle: '3 penalty-free emergency withdrawals remaining for 2024',
          ),
        ],
      ),
    );
  }

  Widget _buildContributionHistory(ThemeData theme) {
    if (_isLoadingContributions) {
      return InfoCard(
        title: 'Contribution History',
        child: const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      );
    }

    if (_contributions.isEmpty) {
      return InfoCard(
        title: 'Contribution History',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No boosts recorded yet. Your next top-up will show here instantly.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }

    return InfoCard(
      title: 'Contribution History',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _contributions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final contribution = _contributions[index];
          return _buildContributionTile(theme, contribution);
        },
      ),
    );
  }

  Widget _buildContributionTile(ThemeData theme, SavingsContributionModel contribution) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GH₵ ${_currencyFormatter.format(contribution.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contribution.channel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contribution.note,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM dd, yyyy · hh:mm a').format(contribution.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostForm(ThemeData theme) {
    final remaining = _remainingAmount;
    final amount = double.tryParse(_amountController.text.trim());
    final projectedTotal = amount != null ? _goal.currentAmount + amount : null;
    final projectedProgress = projectedTotal != null
        ? ((projectedTotal / _goal.targetAmount) * 100).clamp(0, 999).toStringAsFixed(0)
        : null;

    return InfoCard(
      title: 'Boost Savings',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a quick boost to stay ahead of schedule. Minimum boost is GH₵ ${_minBoostAmount.toStringAsFixed(0)}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Amount (GH₵)',
                hintText: remaining > 0 ? _currencyFormatter.format((remaining / 3).clamp(_minBoostAmount, remaining)) : '0.00',
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Enter an amount to boost.';
                }
                final parsed = double.tryParse(trimmed);
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                if (parsed < _minBoostAmount) {
                  return 'Minimum boost is GH₵ ${_minBoostAmount.toStringAsFixed(0)}';
                }
                if (parsed > 1000000) {
                  return 'Amount seems too high. Try a smaller boost.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'Document where this boost is coming from',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: projectedTotal != null
                  ? Container(
                      key: ValueKey(projectedTotal),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Boosting now brings you to GH₵ ${_currencyFormatter.format(projectedTotal)} '
                        '(${projectedProgress}% of your target).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitBoost,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.trending_up_rounded),
              label: Text(_isSubmitting ? 'Recording boost...' : 'Add boost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestones(ThemeData theme) {
    return InfoCard(
      title: 'Milestones',
      child: Column(
        children: [
          for (int i = 0; i < _milestoneThresholds.length; i++) ...[
            _buildMilestone(theme, _milestoneThresholds[i]),
            if (i != _milestoneThresholds.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestone(ThemeData theme, double threshold) {
    final percentLabel = (threshold * 100).toStringAsFixed(0);
    final achievedAt = _milestoneHistory[threshold];
    final isAchieved = achievedAt != null && _goal.progress >= threshold;
    final milestoneAmount = _goal.targetAmount * threshold;
    final amountLabel = _currencyFormatter.format(milestoneAmount);
    final nextThreshold = _milestoneThresholds.firstWhere(
      (value) => _goal.progress < value,
      orElse: () => _milestoneThresholds.last,
    );
    final isNext = !isAchieved && nextThreshold == threshold;
    final nowAmount = (_goal.targetAmount * threshold) - _goal.currentAmount;
    final remainingAmount = _currencyFormatter.format(nowAmount.clamp(0, double.infinity));

    String subtitle;
    if (isAchieved && achievedAt != null) {
      final dateLabel = DateFormat('MMM d, yyyy').format(achievedAt);
      subtitle = 'Unlocked on $dateLabel • ₵$amountLabel saved';
    } else if (isNext) {
      subtitle = 'Only ₵$remainingAmount to reach $percentLabel%. Keep the momentum!';
    } else {
      subtitle = 'Celebrate at ₵$amountLabel saved. Stay consistent to unlock this badge.';
    }

    final Color background;
    final Color iconColor;
    if (isAchieved) {
      background = theme.colorScheme.secondary.withValues(alpha: 0.15);
      iconColor = theme.colorScheme.secondary;
    } else if (isNext) {
      background = theme.colorScheme.primary.withValues(alpha: 0.12);
      iconColor = theme.colorScheme.primary;
    } else {
      background = theme.colorScheme.surfaceVariant.withValues(alpha: 0.4);
      iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAchieved ? Icons.emoji_events_outlined : Icons.flag_rounded,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$percentLabel% milestone',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _recalculateMilestones() {
    final derived = _deriveMilestoneHistory(_goal, _contributions);
    _milestoneHistory
      ..clear()
      ..addAll(derived);
  }

  Map<double, DateTime> _deriveMilestoneHistory(
    SavingsGoalModel goal,
    List<SavingsContributionModel> contributions,
  ) {
    if (goal.targetAmount <= 0) {
      return {};
    }

    final achievements = <double, DateTime>{};
    final sortedContributions = [...contributions]
      ..sort((a, b) => a.date.compareTo(b.date));
    final totalContributionAmount = contributions.fold<double>(0, (sum, c) => sum + c.amount);
    final baseAmount =
        (goal.currentAmount - totalContributionAmount).clamp(0, goal.targetAmount).toDouble();
    double runningAmount = baseAmount;

    final baseProgress = runningAmount / goal.targetAmount;
    for (final threshold in _milestoneThresholds) {
      if (baseProgress >= threshold) {
        achievements[threshold] = goal.createdAt;
      }
    }

    for (final contribution in sortedContributions) {
      runningAmount += contribution.amount;
      final progress = runningAmount / goal.targetAmount;
      for (final threshold in _milestoneThresholds) {
        if (!achievements.containsKey(threshold) && progress >= threshold) {
          achievements[threshold] = contribution.date;
        }
      }
    }

    return achievements;
  }
}
