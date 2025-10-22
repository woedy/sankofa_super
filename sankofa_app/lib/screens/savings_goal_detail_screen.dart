import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/savings_contribution_model.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
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
  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');
  bool _isLoadingContributions = true;
  bool _isSubmitting = false;
  bool _hasChanges = false;

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
    });
  }

  double get _remainingAmount => (_goal.targetAmount - _goal.currentAmount).clamp(0, double.infinity);

  Future<void> _submitBoost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    setState(() => _isSubmitting = true);

    final updatedGoal = await _savingsService.contributeToGoal(
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
      if (updatedGoal != null) {
        _goal = updatedGoal;
        _hasChanges = true;
      }
      _contributions
        ..clear()
        ..addAll(contributions);
      _isSubmitting = false;
      _amountController.clear();
      _noteController.clear();
    });

    if (updatedGoal != null && mounted) {
      final progress = (_goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Boost added! You are now $progress% to your goal.'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to record boost. Please try again.')),
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
              _buildMilestones(theme),
            ],
          ),
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
          _buildMilestone(theme, '25% celebrated', 'Jan 12 • Shared badge with group chat'),
          const SizedBox(height: 16),
          _buildMilestone(theme, '50% achieved', 'Feb 21 • Bonus GH₵50 interest added'),
          const SizedBox(height: 16),
          _buildMilestone(theme, 'Next: 75% boost', 'Scheduled for Apr 04 • In-app party animation'),
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

  Widget _buildMilestone(ThemeData theme, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.85),
                theme.colorScheme.tertiary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events_outlined, color: Colors.white),
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
}
