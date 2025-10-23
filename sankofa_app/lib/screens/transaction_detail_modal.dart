import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/screens/transaction_receipt_modal.dart';

Future<void> showTransactionDetailModal(
  BuildContext context,
  TransactionModel transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, controller) => TransactionDetailModal(
          transaction: transaction,
          scrollController: controller,
        ),
      );
    },
  );
}

class TransactionDetailModal extends StatelessWidget {
  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.scrollController,
  });

  final TransactionModel transaction;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = transaction.type == 'deposit' || transaction.type == 'payout';
    final amountPrefix = isPositive ? '+' : '-';
    final formattedAmount = 'GH₵ ${NumberFormat('#,##0.00').format(transaction.amount)}';
    final statusLabel = _readableStatus(transaction.status);
    final channelLabel = transaction.channel ?? _inferChannel();
    final timeline = _buildTimeline(statusLabel, channelLabel);

    return ModalScaffold(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaction details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(context, amountPrefix, formattedAmount, statusLabel),
                    const SizedBox(height: 16),
                    _buildReceiptActions(context),
                    const SizedBox(height: 24),
                    InfoCard(
                      title: 'Summary',
                      child: Column(
                        children: [
                          InfoRow(label: 'Reference ID', value: transaction.reference ?? transaction.id),
                          InfoRow(label: 'Description', value: transaction.description),
                          InfoRow(
                            label: 'Date & time',
                            value: DateFormat('EEE, dd MMM yyyy • hh:mm a').format(transaction.date),
                          ),
                          InfoRow(label: 'Status', value: statusLabel),
                          if (transaction.fee != null && transaction.fee! > 0)
                            InfoRow(label: 'Processing fees', value: _formatCurrency(transaction.fee!)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    InfoCard(
                      title: 'Settlement details',
                      child: Column(
                        children: [
                          InfoRow(label: 'Channel', value: channelLabel),
                          if (transaction.counterparty != null && transaction.counterparty!.isNotEmpty)
                            InfoRow(label: 'Counterparty', value: transaction.counterparty!),
                          InfoRow(
                            label: 'Created',
                            value: DateFormat('dd MMM yyyy • hh:mm a').format(transaction.createdAt),
                          ),
                          InfoRow(
                            label: 'Last updated',
                            value: DateFormat('dd MMM yyyy • hh:mm a').format(transaction.updatedAt),
                          ),
                        ],
                      ),
                    ),
                    if (timeline.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      InfoCard(
                        title: 'Timeline',
                        child: Column(
                          children: [
                            for (final item in timeline) _buildTimelineTile(context, item),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    String amountPrefix,
    String formattedAmount,
    String statusLabel,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatusChip(context, statusLabel),
              _buildPayoutChip(context),
            ].whereType<Widget>().toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.receipt_long),
          label: const Text('View receipt'),
          onPressed: () => showTransactionReceiptModal(context, transaction),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share receipt (stub)'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share your receipt once the PDF generator is connected.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            showTransactionReceiptModal(context, transaction);
          },
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String statusLabel) {
    final isSuccess = transaction.status == 'success';
    return _buildChip(
      context,
      icon: isSuccess ? Icons.verified_outlined : Icons.hourglass_empty_outlined,
      label: statusLabel,
    );
  }

  Widget? _buildPayoutChip(BuildContext context) {
    final description = transaction.description.toLowerCase();
    if (description.contains('group')) {
      return _buildChip(context, icon: Icons.groups, label: 'Group linked');
    }
    if (description.contains('savings')) {
      return _buildChip(context, icon: Icons.savings_outlined, label: 'Personal goal');
    }
    return null;
  }

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

  Widget _buildTimelineTile(BuildContext context, _TimelineItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  List<_TimelineItem> _buildTimeline(String statusLabel, String channelLabel) {
    final items = <_TimelineItem>[
      _TimelineItem(
        icon: Icons.radio_button_checked,
        title: 'Initiated',
        subtitle:
            '${DateFormat('dd MMM yyyy • hh:mm a').format(transaction.createdAt)} via $channelLabel',
      ),
      if (transaction.fee != null && transaction.fee! > 0)
        _TimelineItem(
          icon: Icons.receipt_long_outlined,
          title: 'Fees assessed',
          subtitle: '${_formatCurrency(transaction.fee!)} processing charge applied',
        ),
      _TimelineItem(
        icon: Icons.shield_outlined,
        title: 'Compliance checks',
        subtitle: 'KYC + AML cleared in under 3 seconds',
      ),
      _TimelineItem(
        icon: Icons.check_circle_outline,
        title: statusLabel,
        subtitle: DateFormat('dd MMM yyyy • hh:mm a').format(transaction.updatedAt),
      ),
    ];
    return items;
  }

  String _formatCurrency(double value) => 'GH₵ ${NumberFormat('#,##0.00').format(value)}';
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
