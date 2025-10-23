import 'package:sankofasave/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TransactionService {
  static const String _transactionsKey = 'transactions';

  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey);
    if (transactionsJson != null && transactionsJson.isNotEmpty) {
      final transactions =
          transactionsJson.map((json) => TransactionModel.fromJson(jsonDecode(json))).toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    }
    final defaultTransactions = _getDefaultTransactions();
    await _saveTransactions(defaultTransactions);
    return defaultTransactions;
  }

  Future<void> _saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, transactionsJson);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final transactions = await getTransactions();
    transactions.insert(0, transaction);
    transactions.sort((a, b) => b.date.compareTo(a.date));
    await _saveTransactions(transactions);
  }

  List<TransactionModel> _getDefaultTransactions() {
    final now = DateTime.now();
    final transactions = [
      TransactionModel(
        id: 'TXN-24001',
        userId: 'user_001',
        amount: 200.00,
        type: 'contribution',
        status: 'success',
        description: 'Contribution to Unity Savers Group',
        date: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        channel: 'Wallet transfer',
        counterparty: 'Unity Savers Group',
        reference: 'CIRC-8821',
      ),
      TransactionModel(
        id: 'TXN-24000',
        userId: 'user_001',
        amount: 500.00,
        type: 'deposit',
        status: 'success',
        description: 'Wallet deposit via MTN MoMo',
        date: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        channel: 'MTN MoMo',
        fee: 3.50,
        reference: 'DEP-547210',
        counterparty: '+233 24 123 4567',
      ),
      TransactionModel(
        id: 'TXN-23998',
        userId: 'user_001',
        amount: 1000.00,
        type: 'payout',
        status: 'success',
        description: 'Payout from Unity Savers Group',
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        channel: 'Group wallet',
        reference: 'PAY-117430',
        counterparty: 'Unity Savers Group',
      ),
      TransactionModel(
        id: 'TXN-23995',
        userId: 'user_001',
        amount: 150.00,
        type: 'savings',
        status: 'success',
        description: 'Personal Savings - Education Fund',
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        channel: 'Wallet transfer',
        reference: 'SAVE-661092',
        counterparty: 'Education Fund Goal',
      ),
      TransactionModel(
        id: 'TXN-23988',
        userId: 'user_001',
        amount: 300.00,
        type: 'withdrawal',
        status: 'success',
        description: 'Withdrawal to Mobile Money',
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        channel: 'Vodafone Cash',
        fee: 2.40,
        reference: 'WDR-772110',
        counterparty: '+233 20 987 6543',
      ),
      TransactionModel(
        id: 'TXN-23980',
        userId: 'user_001',
        amount: 200.00,
        type: 'contribution',
        status: 'success',
        description: 'Contribution to Women Empowerment Circle',
        date: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
        channel: 'Wallet transfer',
        counterparty: 'Women Empowerment Circle',
        reference: 'CIRC-771233',
      ),
      TransactionModel(
        id: 'TXN-23972',
        userId: 'user_001',
        amount: 450.00,
        type: 'withdrawal',
        status: 'pending',
        description: 'Pending withdrawal to bank account',
        date: now.subtract(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 11, hours: 12)),
        channel: 'GTBank',
        reference: 'WDR-449001',
        counterparty: 'GCB 1234567890',
      ),
      TransactionModel(
        id: 'TXN-23970',
        userId: 'user_001',
        amount: 120.00,
        type: 'deposit',
        status: 'failed',
        description: 'Failed mobile money top-up',
        date: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 14)),
        channel: 'AirtelTigo Money',
        reference: 'DEP-338211',
        counterparty: '+233 55 123 0001',
      ),
    ];
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}
