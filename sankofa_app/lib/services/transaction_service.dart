import 'package:sankofasave/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TransactionService {
  static const String _transactionsKey = 'transactions';

  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey);
    if (transactionsJson != null && transactionsJson.isNotEmpty) {
      return transactionsJson.map((json) => TransactionModel.fromJson(jsonDecode(json))).toList();
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
    await _saveTransactions(transactions);
  }

  List<TransactionModel> _getDefaultTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'txn_001',
        userId: 'user_001',
        amount: 200.00,
        type: 'contribution',
        status: 'success',
        description: 'Contribution to Unity Savers Group',
        date: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        id: 'txn_002',
        userId: 'user_001',
        amount: 500.00,
        type: 'deposit',
        status: 'success',
        description: 'Mobile Money Deposit',
        date: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'txn_003',
        userId: 'user_001',
        amount: 1000.00,
        type: 'payout',
        status: 'success',
        description: 'Payout from Unity Savers Group',
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 'txn_004',
        userId: 'user_001',
        amount: 150.00,
        type: 'savings',
        status: 'success',
        description: 'Personal Savings - Education Fund',
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      TransactionModel(
        id: 'txn_005',
        userId: 'user_001',
        amount: 300.00,
        type: 'withdrawal',
        status: 'success',
        description: 'Withdrawal to Mobile Money',
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      TransactionModel(
        id: 'txn_006',
        userId: 'user_001',
        amount: 200.00,
        type: 'contribution',
        status: 'success',
        description: 'Contribution to Women Empowerment Circle',
        date: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }
}
