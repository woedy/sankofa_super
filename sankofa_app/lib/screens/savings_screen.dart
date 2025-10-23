import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/screens/savings_goal_detail_screen.dart';
import 'package:sankofasave/screens/savings_goal_wizard_screen.dart';
import 'package:sankofasave/services/savings_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

enum SavingsSortOption { progress, deadline }

class _SavingsScreenState extends State<SavingsScreen> {
  static const List<_SortOption> _sortOptions = [
    _SortOption(
      option: SavingsSortOption.progress,
      label: 'Progress',
      icon: Icons.speed,
      description: 'Lowest completion first',
    ),
    _SortOption(
      option: SavingsSortOption.deadline,
      label: 'Deadline',
      icon: Icons.event,
      description: 'Soonest due first',
    ),
  ];

  final SavingsService _savingsService = SavingsService();
  List<SavingsGoalModel> _goals = [];
  List<SavingsGoalModel> _allGoals = [];
  SavingsSortOption _activeSort = SavingsSortOption.progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    if (_goals.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    final goals = await _savingsService.getGoals();
    if (!mounted) return;
    setState(() {
      _allGoals = goals;
      _goals = _sortedGoals(_activeSort, goals);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Personal Savings'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGoals,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
                itemCount: _goals.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Active savings goals',
                            subtitle:
                                'Sort by progress or upcoming deadline to spot which goal needs attention first.',
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          const SizedBox(height: 12),
                          ActionChipRow(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            items: [
                              for (final option in _sortOptions)
                                ActionChipItem(
                                  label: option.label,
                                  icon: option.icon,
                                  isSelected: option.option == _activeSort,
                                ),
                            ],
                            onSelected: (index, _) => _onSortSelected(_sortOptions[index].option),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _activeSortDescription,
                              key: ValueKey(_activeSortDescription),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final goal = _goals[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGoalCard(goal),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'savings_fab',
        onPressed: _launchGoalWizard,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Goal', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _launchGoalWizard() async {
    final createdGoal = await Navigator.push<SavingsGoalModel>(
      context,
      MaterialPageRoute(builder: (_) => const SavingsGoalWizardScreen()),
    );

    if (createdGoal != null) {
      await _loadGoals();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${createdGoal.title}” is now live in your savings!'),
        ),
      );
    }
  }

  Widget _buildGoalCard(SavingsGoalModel goal) {
    final categoryColor = _getCategoryColor(goal.category);
    final progressPercent = '${(goal.progress * 100).toStringAsFixed(0)}%';
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<SavingsGoalModel>(
          context,
          MaterialPageRoute(
            builder: (_) => SavingsGoalDetailScreen(goal: goal),
          ),
        );
        if (result != null) {
          _handleGoalUpdated(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
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
                GradientIconBadge(
                  icon: _getCategoryIcon(goal.category),
                  colors: [categoryColor, Theme.of(context).colorScheme.secondary],
                  diameter: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        progressPercent,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProgressSummaryBar(
              progress: goal.progress,
              label: 'Progress toward target',
              secondaryLabel: 'Due ${DateFormat('MMM dd, yyyy').format(goal.deadline)}',
              color: categoryColor,
            ),
            const SizedBox(height: 12),
            Text(
              _milestoneMicrocopy(goal),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMeta('Current', 'GH₵ ${NumberFormat('#,##0.00').format(goal.currentAmount)}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeta('Target', 'GH₵ ${NumberFormat('#,##0.00').format(goal.targetAmount)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoalUpdated(SavingsGoalModel updatedGoal) {
    final allGoals = List<SavingsGoalModel>.from(_allGoals);
    final index = allGoals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index == -1) return;
    allGoals[index] = updatedGoal;
    setState(() {
      _allGoals = allGoals;
      _goals = _sortedGoals(_activeSort, allGoals);
    });
  }

  Widget _buildMeta(String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _onSortSelected(SavingsSortOption option) {
    setState(() {
      _activeSort = option;
      _goals = _sortedGoals(option, _allGoals);
    });
  }

  List<SavingsGoalModel> _sortedGoals(SavingsSortOption option, List<SavingsGoalModel> source) {
    final sorted = List<SavingsGoalModel>.from(source);
    switch (option) {
      case SavingsSortOption.progress:
        sorted.sort((a, b) {
          final progressCompare = a.progress.compareTo(b.progress);
          if (progressCompare != 0) {
            return progressCompare;
          }
          return a.deadline.compareTo(b.deadline);
        });
        break;
      case SavingsSortOption.deadline:
        sorted.sort((a, b) {
          final deadlineCompare = a.deadline.compareTo(b.deadline);
          if (deadlineCompare != 0) {
            return deadlineCompare;
          }
          return a.progress.compareTo(b.progress);
        });
        break;
    }
    return sorted;
  }

  String get _activeSortDescription {
    final option = _sortOptions.firstWhere((item) => item.option == _activeSort);
    return 'Sorted by ${option.label.toLowerCase()} • ${option.description}';
  }

  String _milestoneMicrocopy(SavingsGoalModel goal) {
    final progress = goal.progress.clamp(0.0, 1.0);
    final now = DateTime.now();
    final daysRemaining = goal.deadline.difference(now).inDays;

    if (progress >= 1) {
      return 'Goal achieved! Schedule your payout when you’re ready.';
    }

    if (daysRemaining < 0) {
      return 'Deadline passed — extend your plan to keep the savings momentum.';
    }

    final milestones = [0.25, 0.5, 0.75, 1.0];
    final nextMilestone = milestones.firstWhere((threshold) => progress < threshold, orElse: () => 1.0);
    final remainingAmount = (goal.targetAmount * nextMilestone) - goal.currentAmount;
    final milestoneLabel = (nextMilestone * 100).toStringAsFixed(0);
    final timeToDeadline = _formatTimeToDeadline(daysRemaining);

    if (remainingAmount <= 1) {
      return 'You’re on the cusp of $milestoneLabel% — even a small top-up this week gets you there with $timeToDeadline.';
    }

    final formattedAmount = NumberFormat('#,##0').format(remainingAmount.ceil());
    return 'Top up GH₵ $formattedAmount to reach $milestoneLabel% with $timeToDeadline.';
  }

  String _formatTimeToDeadline(int daysRemaining) {
    if (daysRemaining <= 0) {
      return 'no time to spare';
    }
    if (daysRemaining == 1) {
      return '1 day left';
    }
    if (daysRemaining < 7) {
      return '$daysRemaining days left';
    }
    final weeks = (daysRemaining / 7).floor();
    if (weeks == 1) {
      return '1 week remaining';
    }
    if (weeks < 5) {
      return '$weeks weeks remaining';
    }
    final months = (daysRemaining / 30).floor();
    if (months <= 1) {
      return 'about a month remaining';
    }
    return '$months months remaining';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return Icons.school;
      case 'business':
        return Icons.business_center;
      case 'emergency':
        return Icons.emergency;
      case 'travel':
        return Icons.flight;
      case 'home':
        return Icons.home;
      default:
        return Icons.savings;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return const Color(0xFF1E3A8A);
      case 'business':
        return const Color(0xFF14B8A6);
      case 'emergency':
        return const Color(0xFFDC2626);
      case 'travel':
        return const Color(0xFF0891B2);
      case 'home':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

class _SortOption {
  const _SortOption({
    required this.option,
    required this.label,
    required this.icon,
    required this.description,
  });

  final SavingsSortOption option;
  final String label;
  final IconData icon;
  final String description;
}
