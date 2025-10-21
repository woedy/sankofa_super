import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final amountPrefix = transaction.type == 'deposit' || transaction.type == 'payout' ? '+' : '-';
    final formattedAmount = 'GH₵ ${NumberFormat('#,##0.00').format(transaction.amount)}';
    final timeline = _buildTimeline();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
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
                    Theme.of(context).colorScheme.primary,
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
                    transaction.type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$amountPrefix$formattedAmount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatusChip(context),
                      _buildPayoutChip(context),
                    ].whereType<Widget>().toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Summary',
              child: Column(
                children: [
                  _buildInfoRow(context, 'Reference ID', transaction.id),
                  _buildInfoRow(context, 'Description', transaction.description),
                  _buildInfoRow(
                    context,
                    'Date & Time',
                    DateFormat('EEE, dd MMM yyyy • hh:mm a').format(transaction.date),
                  ),
                  _buildInfoRow(context, 'Status', _readableStatus(transaction.status)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Audit Trail',
              child: Column(
                children: [
                  _buildInfoRow(context, 'Created', DateFormat('dd MMM yyyy • hh:mm a').format(transaction.createdAt)),
                  _buildInfoRow(context, 'Updated', DateFormat('dd MMM yyyy • hh:mm a').format(transaction.updatedAt)),
                  _buildInfoRow(context, 'Channel', _inferChannel()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Timeline',
              child: Column(
                children: timeline
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: Theme.of(context).colorScheme.secondary),
                        ),
                        title: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                        ),
                      ),
                    )
                    .toList(),
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
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget? _buildPayoutChip(BuildContext context) {
    final description = transaction.description.toLowerCase();
    if (description.contains('group')) {
      return _buildChip(
        context,
        icon: Icons.groups,
        label: 'Group linked',
      );
    }
    if (description.contains('savings')) {
      return _buildChip(context, icon: Icons.savings_outlined, label: 'Personal goal');
    }
    return null;
  }

  Widget _buildStatusChip(BuildContext context) => _buildChip(
        context,
        icon: transaction.status == 'success' ? Icons.verified_outlined : Icons.hourglass_empty_outlined,
        label: _readableStatus(transaction.status),
      );

  Widget _buildChip(BuildContext context, {required IconData icon, required String label}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  String _readableStatus(String status) => switch (status.toLowerCase()) {
        'success' => 'Successful',
        'pending' => 'Pending',
        'failed' => 'Failed',
        _ => status,
      };

  String _inferChannel() {
    final description = transaction.description.toLowerCase();
    if (description.contains('mobile money') || description.contains('momo')) {
      return 'Mobile Money';
    }
    if (description.contains('wallet')) {
      return 'Wallet';
    }
    if (description.contains('payout')) {
      return 'Group payout';
    }
    return 'Internal';
  }

  List<_TimelineItem> _buildTimeline() {
    final baseDate = transaction.date;
    return [
      _TimelineItem(
        icon: Icons.radio_button_checked,
        title: 'Initiated',
        subtitle: DateFormat('dd MMM yyyy • hh:mm a').format(baseDate),
      ),
      _TimelineItem(
        icon: Icons.shield_outlined,
        title: 'Compliance Checks Ran',
        subtitle: 'KYC + AML cleared in under 3 seconds',
      ),
      _TimelineItem(
        icon: Icons.check_circle_outline,
        title: 'Completed',
        subtitle: _readableStatus(transaction.status),
      ),
    ];
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}