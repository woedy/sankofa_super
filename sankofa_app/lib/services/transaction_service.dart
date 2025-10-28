import 'dart:convert';

import 'package:sankofasave/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class TransactionService {
  TransactionService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _localTransactionsKey = 'transactions_local';

  List<TransactionModel>? _cachedRemoteTransactions;

  Future<List<TransactionModel>> getTransactions({bool forceRefresh = false}) async {
    final remote = await _fetchRemoteTransactions(forceRefresh: forceRefresh);
    final local = await _loadLocalTransactions();
    final combined = <TransactionModel>[...remote, ...local]
      ..sort((a, b) => b.date.compareTo(a.date));
    return combined;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final local = await _loadLocalTransactions();
    local.insert(0, transaction);
    await _saveLocalTransactions(local);
  }

  void recordRemoteTransaction(TransactionModel transaction) {
    final current = List<TransactionModel>.from(_cachedRemoteTransactions ?? const []);
    final existingIndex = current.indexWhere((item) => item.id == transaction.id);
    if (existingIndex >= 0) {
      current[existingIndex] = transaction;
    } else {
      current.insert(0, transaction);
    }
    current.sort((a, b) => b.date.compareTo(a.date));
    _cachedRemoteTransactions = current;
  }

  Future<void> clearLocalTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localTransactionsKey);
  }

  Future<List<TransactionModel>> _fetchRemoteTransactions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRemoteTransactions != null) {
      return _cachedRemoteTransactions!;
    }

    try {
      final response = await _apiClient.get(
        '/api/transactions/',
        queryParameters: const {'page_size': '100'},
      );

      List<dynamic> payload;
      if (response is Map<String, dynamic>) {
        payload = (response['results'] as List?) ?? const [];
      } else if (response is List) {
        payload = response;
      } else {
        payload = const [];
      }

      final transactions = payload
          .whereType<Map>()
          .map((item) => TransactionModel.fromJson(item.cast<String, dynamic>()))
          .toList();
      _cachedRemoteTransactions = transactions;
      return transactions;
    } catch (_) {
      _cachedRemoteTransactions ??= const [];
      return _cachedRemoteTransactions!;
    }
  }

  Future<List<TransactionModel>> _loadLocalTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_localTransactionsKey);
    if (transactionsJson == null || transactionsJson.isEmpty) {
      return [];
    }

    return transactionsJson
        .map((json) => TransactionModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocalTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((transaction) => jsonEncode(transaction.toJson())).toList();
    await prefs.setStringList(_localTransactionsKey, transactionsJson);
  }
}
