import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/savings_goal_model.dart';

class SavingsGoalDetailScreen extends StatelessWidget {
  const SavingsGoalDetailScreen({super.key, required this.goal});

  final SavingsGoalModel goal;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final percentage = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final remaining = goal.targetAmount - goal.currentAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goal'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
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
                    goal.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goal.category,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: goal.progress.clamp(0.0, 1.0),
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
                        'Due ${DateFormat('dd MMM yyyy').format(goal.deadline)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Financial Overview',
              child: Column(
                children: [
                  _buildInfoRow(context, 'Target', 'GH₵ ${formatter.format(goal.targetAmount)}'),
                  _buildInfoRow(context, 'Saved so far', 'GH₵ ${formatter.format(goal.currentAmount)}'),
                  _buildInfoRow(context, 'Remaining', 'GH₵ ${formatter.format(remaining)}'),
                  _buildInfoRow(context, 'Start Date', DateFormat('dd MMM yyyy').format(goal.createdAt)),
                  _buildInfoRow(context, 'Last Updated', DateFormat('dd MMM yyyy').format(goal.updatedAt)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Automation Plan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChecklistItem(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: 'Weekly top-up scheduled',
                    subtitle: 'GH₵ ${(goal.targetAmount / 26).toStringAsFixed(2)} auto-debits every Monday',
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistItem(
                    context,
                    icon: Icons.link_outlined,
                    title: 'Linked to Unity Savers payout',
                    subtitle: '10% of group payout nudged into this goal automatically',
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistItem(
                    context,
                    icon: Icons.shield_moon_outlined,
                    title: 'Safety net active',
                    subtitle: '3 penalty-free emergency withdrawals remaining for 2024',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Milestones',
              child: Column(
                children: [
                  _buildMilestone(context, '25% celebrated', 'Jan 12 • Shared badge with group chat'),
                  const SizedBox(height: 16),
                  _buildMilestone(context, '50% achieved', 'Feb 21 • Bonus GH₵50 interest added'),
                  const SizedBox(height: 16),
                  _buildMilestone(context, 'Next: 75% boost', 'Scheduled for Apr 04 • In-app party animation'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _buildInfoRow(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _buildChecklistItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildMilestone(BuildContext context, String title, String subtitle) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.85),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
}