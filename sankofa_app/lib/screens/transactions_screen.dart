import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/screens/deposit_flow_screen.dart';
import 'package:sankofasave/screens/withdrawal_flow_screen.dart';
import 'package:sankofasave/screens/transaction_detail_modal.dart';
import 'package:sankofasave/services/cashflow_export_service.dart';
import 'package:sankofasave/services/transaction_service.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class _FilterDefinition {
  const _FilterDefinition({
    required this.key,
    required this.label,
    this.icon,
  });

  final String key;
  final String label;
  final IconData? icon;
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final CashflowExportService _cashflowExportService = CashflowExportService();
  List<TransactionModel> _transactions = [];
  late final List<_FilterDefinition> _typeDefinitions;
  late final List<_FilterDefinition> _statusDefinitions;
  late Set<String> _selectedTypeKeys;
  late Set<String> _selectedStatusKeys;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _loadTransactions();
  }

  void _initializeFilters() {
    _typeDefinitions = const [
      _FilterDefinition(key: 'deposit', label: 'Deposits', icon: Icons.arrow_downward),
      _FilterDefinition(key: 'withdrawal', label: 'Withdrawals', icon: Icons.arrow_upward),
      _FilterDefinition(key: 'contribution', label: 'Contributions', icon: Icons.groups),
      _FilterDefinition(key: 'payout', label: 'Payouts', icon: Icons.wallet),
      _FilterDefinition(key: 'savings', label: 'Savings', icon: Icons.savings),
    ];

    _statusDefinitions = const [
      _FilterDefinition(key: 'success', label: 'Success', icon: Icons.check_circle),
      _FilterDefinition(key: 'pending', label: 'Pending', icon: Icons.hourglass_top),
      _FilterDefinition(key: 'failed', label: 'Failed', icon: Icons.error_outline),
    ];

    _selectedTypeKeys = _typeDefinitions.map((definition) => definition.key).toSet();
    _selectedStatusKeys = _statusDefinitions.map((definition) => definition.key).toSet();
    _selectedRange = null;
  }

  Future<void> _loadTransactions() async {
    final transactions = await _transactionService.getTransactions();
    if (!mounted) return;
    setState(() => _transactions = transactions);
  }

  List<TransactionModel> get _filteredTransactions {
    Iterable<TransactionModel> filtered = _transactions;

    if (_selectedTypeKeys.length != _typeDefinitions.length && _selectedTypeKeys.isNotEmpty) {
      filtered = filtered.where((transaction) => _selectedTypeKeys.contains(transaction.type));
    } else if (_selectedTypeKeys.isEmpty) {
      filtered = const Iterable<TransactionModel>.empty();
    }

    if (_selectedStatusKeys.length != _statusDefinitions.length && _selectedStatusKeys.isNotEmpty) {
      filtered = filtered.where((transaction) => _selectedStatusKeys.contains(transaction.status));
    } else if (_selectedStatusKeys.isEmpty) {
      filtered = const Iterable<TransactionModel>.empty();
    }

    if (_selectedRange != null) {
      final start = DateTime(_selectedRange!.start.year, _selectedRange!.start.month, _selectedRange!.start.day);
      final end = DateTime(_selectedRange!.end.year, _selectedRange!.end.month, _selectedRange!.end.day, 23, 59, 59, 999);
      filtered = filtered.where((transaction) => !transaction.date.isBefore(start) && !transaction.date.isAfter(end));
    }

    return filtered.toList();
  }

  bool get _hasActiveFilters =>
      _selectedTypeKeys.length != _typeDefinitions.length ||
      _selectedStatusKeys.length != _statusDefinitions.length ||
      _selectedRange != null;

  List<ActionChipItem> get _typeFilterChips => [
        for (final definition in _typeDefinitions)
          ActionChipItem(
            label: definition.label,
            icon: definition.icon,
            isSelected: _selectedTypeKeys.contains(definition.key),
          ),
      ];

  List<ActionChipItem> get _statusFilterChips => [
        for (final definition in _statusDefinitions)
          ActionChipItem(
            label: definition.label,
            icon: definition.icon,
            isSelected: _selectedStatusKeys.contains(definition.key),
          ),
      ];

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _selectedRange?.start ?? now.subtract(const Duration(days: 30));
    final initialEnd = _selectedRange?.end ?? now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      saveText: 'Apply',
    );

    if (picked != null && mounted) {
      setState(() => _selectedRange = picked);
    }
  }

  void _clearDateRange() {
    setState(() => _selectedRange = null);
  }

  void _resetFilters() {
    setState(() {
      _selectedTypeKeys = _typeDefinitions.map((definition) => definition.key).toSet();
      _selectedStatusKeys = _statusDefinitions.map((definition) => definition.key).toSet();
      _selectedRange = null;
    });
  }

  Future<void> _handleExport() async {
    final filtered = _filteredTransactions;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions match your filters to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final csv = await _cashflowExportService.buildCsv(filtered);
    final filename = _cashflowExportService.generateFilename();
    if (!mounted) return;

    final preview = _buildExportPreview(csv);
    final parentContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ModalScaffold(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export cashflow history',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'We generated a CSV stub you can copy or share once backend storage is wired up.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              InfoCard(
                title: 'Export summary',
                child: Column(
                  children: [
                    InfoRow(label: 'File name', value: filename),
                    InfoRow(label: 'Entries included', value: '${filtered.length}'),
                    InfoRow(label: 'Filters applied', value: _hasActiveFilters ? 'Yes' : 'No'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              InfoCard(
                title: 'CSV preview',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      preview,
                      style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy CSV to clipboard'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: csv));
                  if (!mounted) return;
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Copied ${filtered.length} transactions to your clipboard.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Email PDF stub (coming soon)'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('PDF exports will send once the Django service is live.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildExportPreview(String csv) {
    final trimmed = csv.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final lines = trimmed.split('\n');
    if (lines.length <= 6) {
      return lines.join('\n');
    }
    final previewLines = <String>[]
      ..addAll(lines.take(6))
      ..add('… (${lines.length - 6} more rows)');
    return previewLines.join('\n');
  }

  Future<void> _openDepositFlow() async {
    final result = await Navigator.of(context).push<bool>(
      RouteTransitions.slideUp(const DepositFlowScreen()),
    );
    if (result == true) {
      await _loadTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deposit added to your history.')),
      );
    }
  }

  Future<void> _openWithdrawalFlow() async {
    final result = await Navigator.of(context).push<WithdrawalSubmissionStatus>(
      RouteTransitions.slideUp(const WithdrawalFlowScreen()),
    );
    if (result != null) {
      await _loadTransactions();
      if (!mounted) return;
      final message = switch (result) {
        WithdrawalSubmissionStatus.success =>
            'Withdrawal recorded and wallet update is on its way.',
        WithdrawalSubmissionStatus.pending =>
            'Withdrawal queued for review. Check notifications for updates.',
        WithdrawalSubmissionStatus.failed =>
            'Withdrawal attempt logged but needs follow-up.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatRange(DateTimeRange range) {
    final sameYear = range.start.year == range.end.year;
    final startFormatter = sameYear ? DateFormat('MMM d') : DateFormat('MMM d, yyyy');
    final endFormatter = DateFormat('MMM d, yyyy');
    final start = startFormatter.format(range.start);
    final end = endFormatter.format(range.end);
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transactions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export cashflow',
            onPressed: _handleExport,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasActiveFilters
                      ? 'Showing results with active filters'
                      : 'Tap to narrow by type, status, or date range',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 520;
                    final depositButton = FilledButton.icon(
                      onPressed: _openDepositFlow,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('New deposit'),
                    );
                    final withdrawalButton = OutlinedButton.icon(
                      onPressed: _openWithdrawalFlow,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('New withdrawal'),
                    );
                    final resetButton = _hasActiveFilters
                        ? TextButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset filters'),
                          )
                        : null;

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: depositButton),
                              const SizedBox(width: 12),
                              Expanded(child: withdrawalButton),
                            ],
                          ),
                          if (resetButton != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: resetButton),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        depositButton,
                        const SizedBox(width: 12),
                        withdrawalButton,
                        if (resetButton != null) ...[
                          const SizedBox(width: 12),
                          resetButton,
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ActionChipRow(
                  items: _typeFilterChips,
                  multiSelect: true,
                  onToggled: (index, selected, item) {
                    final key = _typeDefinitions[index].key;
                    setState(() {
                      if (selected) {
                        _selectedTypeKeys.add(key);
                      } else {
                        _selectedTypeKeys.remove(key);
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ActionChipRow(
                  items: _statusFilterChips,
                  multiSelect: true,
                  onToggled: (index, selected, item) {
                    final key = _statusDefinitions[index].key;
                    setState(() {
                      if (selected) {
                        _selectedStatusKeys.add(key);
                      } else {
                        _selectedStatusKeys.remove(key);
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_selectedRange == null ? 'Select date range' : _formatRange(_selectedRange!)),
                      ),
                    ),
                    if (_selectedRange != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Clear date range',
                        icon: const Icon(Icons.close),
                        onPressed: _clearDateRange,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _filteredTransactions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                      children: [
                        _buildEmptyState(),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _filteredTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTransactionCard(transaction),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(height: 20),
        Text(
          'No transactions match your filters',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Try widening the date range or adjusting the type and status selections.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset filters'),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
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
                        DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.date),
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
                  transaction.type.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
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
