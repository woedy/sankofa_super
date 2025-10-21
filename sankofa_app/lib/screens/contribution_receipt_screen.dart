import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/ui/components/ui.dart';

class ContributionReceiptScreen extends StatelessWidget {
  const ContributionReceiptScreen({
    super.key,
    required this.transaction,
    required this.group,
    required this.remainingBalance,
  });

  final TransactionModel transaction;
  final SusuGroupModel group;
  final double remainingBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM dd, yyyy · hh:mm a').format(transaction.date);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close receipt',
        ),
        title: const Text('Contribution Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(theme),
            const SizedBox(height: 24),
            InfoCard(
              title: 'Contribution summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(theme, 'Amount', _formatCurrency(transaction.amount), isHighlighted: true),
                  _buildDivider(theme),
                  _buildInfoRow(theme, 'Group', group.name),
                  _buildDivider(theme),
                  _buildInfoRow(theme, 'Transaction ID', transaction.id),
                  _buildDivider(theme),
                  _buildInfoRow(theme, 'Processed on', formattedDate),
                  _buildDivider(theme),
                  _buildInfoRow(theme, 'Wallet balance (after)', _formatCurrency(remainingBalance)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            InfoCard(
              title: 'What happens next?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChecklistItem(
                    theme,
                    icon: Icons.verified_rounded,
                    label: 'Your contribution has been logged for this cycle.',
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistItem(
                    theme,
                    icon: Icons.people_alt_rounded,
                    label: 'Group admins and members can now view this update.',
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistItem(
                    theme,
                    icon: Icons.event_available_rounded,
                    label: 'Stay ready for the payout rotation on ${DateFormat('MMM dd').format(group.nextPayoutDate)}.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleShare(context),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              'Contribution successful',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _formatCurrency(transaction.amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Debited from wallet · ${group.name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    bool isHighlighted = false,
  }) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDivider(ThemeData theme) => Divider(
        height: 1,
        thickness: 1,
        color: theme.colorScheme.outline.withValues(alpha: 0.08),
      );

  Widget _buildChecklistItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );

  void _handleShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share receipt coming soon.'),
      ),
    );
  }

  String _formatCurrency(double amount) =>
      'GH₵ ${NumberFormat('#,##0.00').format(amount)}';
}
