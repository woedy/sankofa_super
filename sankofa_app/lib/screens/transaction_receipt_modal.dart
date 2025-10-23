import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

Future<void> showTransactionReceiptModal(
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
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, controller) => TransactionReceiptModal(
          transaction: transaction,
          scrollController: controller,
        ),
      );
    },
  );
}

class TransactionReceiptModal extends StatefulWidget {
  const TransactionReceiptModal({
    super.key,
    required this.transaction,
    required this.scrollController,
  });

  final TransactionModel transaction;
  final ScrollController scrollController;

  @override
  State<TransactionReceiptModal> createState() => _TransactionReceiptModalState();
}

class _TransactionReceiptModalState extends State<TransactionReceiptModal> {
  final UserService _userService = UserService();
  final DateFormat _fullDateFormatter = DateFormat('EEE, dd MMM yyyy • hh:mm a');
  final DateFormat _fileDateFormatter = DateFormat('yyyyMMdd_HHmm');
  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await _userService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = widget.transaction;
    final isPositive = transaction.type == 'deposit' || transaction.type == 'payout';
    final amountPrefix = isPositive ? '+' : '-';
    final formattedAmount =
        'GH₵ ${_currencyFormatter.format(transaction.amount)}';
    final statusLabel = _readableStatus(transaction.status);
    final receiptId = transaction.reference ?? transaction.id;
    final filename =
        'sankofa_receipt_${transaction.type}_${_fileDateFormatter.format(transaction.date)}.pdf';

    return ModalScaffold(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cashflow receipt',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Close receipt',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
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
                                  color: Colors.white.withValues(alpha: 0.75),
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
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildStatusChip(theme, statusLabel),
                                  _buildReceiptChip(theme, receiptId),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        InfoCard(
                          title: 'Payment summary',
                          child: Column(
                            children: [
                              InfoRow(label: 'Receipt ID', value: receiptId),
                              InfoRow(
                                label: 'Generated',
                                value: _fullDateFormatter.format(transaction.date),
                              ),
                              InfoRow(label: 'Status', value: statusLabel),
                              if (transaction.fee != null && transaction.fee! > 0)
                                InfoRow(
                                  label: 'Processing fees',
                                  value: _formatCurrency(transaction.fee!),
                                ),
                              InfoRow(
                                label: 'Net amount',
                                value: _formatCurrency(
                                  isPositive
                                      ? transaction.amount - (transaction.fee ?? 0)
                                      : transaction.amount + (transaction.fee ?? 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        InfoCard(
                          title: 'Account holder',
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'Name',
                                value: _user?.name ?? 'Wallet owner',
                              ),
                              if (_user?.phone != null)
                                InfoRow(
                                  label: 'Phone',
                                  value: _user!.phone,
                                ),
                              InfoRow(
                                label: 'Account ID',
                                value: widget.transaction.userId,
                              ),
                            ],
                          ),
                        ),
                        if (transaction.channel != null ||
                            transaction.counterparty != null) ...[
                          const SizedBox(height: 24),
                          InfoCard(
                            title: 'Settlement details',
                            child: Column(
                              children: [
                                if (transaction.channel != null)
                                  InfoRow(
                                    label: 'Channel',
                                    value: transaction.channel!,
                                  ),
                                if (transaction.counterparty != null &&
                                    transaction.counterparty!.isNotEmpty)
                                  InfoRow(
                                    label: 'Counterparty',
                                    value: transaction.counterparty!,
                                  ),
                                InfoRow(
                                  label: 'Description',
                                  value: transaction.description,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        InfoCard(
                          title: 'Regulatory note',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'This digital receipt confirms a simulated cashflow movement. '
                                'Share or download it for your records. Final PDFs will be '
                                'issued automatically once the Django backend goes live.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share PDF (stub)'),
                  onPressed: () => _handleShare(context, filename),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Download $filename'),
                  onPressed: () => _handleDownload(context, filename),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy receipt reference'),
                  onPressed: () => _copyReference(context, receiptId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num value) => 'GH₵ ${_currencyFormatter.format(value)}';

  String _readableStatus(String status) => switch (status) {
        'success' => 'Successful',
        'pending' => 'Pending review',
        'failed' => 'Failed',
        _ => status,
      };

  Widget _buildStatusChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildReceiptChip(ThemeData theme, String receiptId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            receiptId,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleShare(BuildContext context, String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share sheet for $filename will appear once connected.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDownload(BuildContext context, String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF download for $filename is mocked for now.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyReference(BuildContext context, String reference) async {
    await Clipboard.setData(ClipboardData(text: reference));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $reference to clipboard.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
