import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/savings_goal_model.dart';
import 'package:sankofasave/screens/savings_goal_detail_screen.dart';
import 'package:sankofasave/services/savings_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final SavingsService _savingsService = SavingsService();
  List<SavingsGoalModel> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _savingsService.getGoals();
    setState(() => _goals = goals);
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
        child: _goals.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGoalCard(goal),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'savings_fab',
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Goal', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoalModel goal) {
    final categoryColor = _getCategoryColor(goal.category);
    final progressPercent = '${(goal.progress * 100).toStringAsFixed(0)}%';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavingsGoalDetailScreen(goal: goal),
        ),
      ),
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
