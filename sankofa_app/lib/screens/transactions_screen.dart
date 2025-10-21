import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/screens/transaction_detail_screen.dart';
import 'package:sankofasave/services/transaction_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  List<TransactionModel> _transactions = [];
  late List<ActionChipItem> _filters;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _loadTransactions();
  }

  void _initializeFilters() {
    _filters = const [
      ActionChipItem(label: 'All', icon: Icons.list),
      ActionChipItem(label: 'Deposit', icon: Icons.arrow_downward),
      ActionChipItem(label: 'Withdrawal', icon: Icons.arrow_upward),
      ActionChipItem(label: 'Contribution', icon: Icons.groups),
      ActionChipItem(label: 'Payout', icon: Icons.wallet),
      ActionChipItem(label: 'Savings', icon: Icons.savings),
    ];
  }

  Future<void> _loadTransactions() async {
    final transactions = await _transactionService.getTransactions();
    setState(() => _transactions = transactions);
  }

  List<TransactionModel> get _filteredTransactions {
    final selected = _filters.firstWhere((item) => item.isSelected, orElse: () => _filters.first);
    if (selected.label == 'All') return _transactions;
    return _transactions.where((t) => t.type == selected.label.toLowerCase()).toList();
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
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: ActionChipRow(
              items: _filters,
              onSelected: (index, item) {
                setState(() {
                  _filters = [
                    for (var i = 0; i < _filters.length; i++)
                      ActionChipItem(
                        label: _filters[i].label,
                        icon: _filters[i].icon,
                        isSelected: i == index,
                      ),
                  ];
                });
              },
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _filteredTransactions.isEmpty
              ? const Center(child: Text('No transactions found'))
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

  Widget _buildTransactionCard(TransactionModel transaction) {
    final color = _getTransactionColor(transaction.type);
    final theme = Theme.of(context);
    final isPositive = transaction.type == 'deposit' || transaction.type == 'payout';
    final amountPrefix = isPositive ? '+' : '-';
    final statusColor = transaction.status == 'success'
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: transaction),
        ),
      ),
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
