import 'api_client.dart';
import 'transaction_service.dart';
import '../models/transaction_model.dart';

class WalletOperationResult {
  WalletOperationResult({
    required this.transaction,
    required this.walletBalance,
    required this.walletUpdatedAt,
    this.platformBalance,
  });

  final TransactionModel transaction;
  final double walletBalance;
  final DateTime walletUpdatedAt;
  final double? platformBalance;

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  factory WalletOperationResult.fromApi(Map<String, dynamic> json) {
    final transactionJson = json['transaction'] as Map<String, dynamic>?;
    final walletJson = json['wallet'] as Map<String, dynamic>?;
    final platformJson = json['platformWallet'] as Map<String, dynamic>?;

    if (transactionJson == null || walletJson == null) {
      throw StateError('Malformed wallet response');
    }

    final transaction = TransactionModel.fromJson(
      Map<String, dynamic>.from(transactionJson),
    );
    final balance = _parseDouble(walletJson['balance']);
    final updatedAtRaw = walletJson['updatedAt'] as String?;

    return WalletOperationResult(
      transaction: transaction,
      walletBalance: balance,
      walletUpdatedAt: DateTime.tryParse(updatedAtRaw ?? '') ?? DateTime.now(),
      platformBalance: platformJson == null ? null : _parseDouble(platformJson['balance']),
    );
  }
}

class WalletService {
  WalletService({ApiClient? apiClient, TransactionService? transactionService})
      : _apiClient = apiClient ?? ApiClient(),
        _transactionService = transactionService ?? TransactionService();

  final ApiClient _apiClient;
  final TransactionService _transactionService;

  String _formatCurrency(num value) => value.toStringAsFixed(2);

  Future<WalletOperationResult> deposit({
    required double amount,
    String? channel,
    String? reference,
    double? fee,
    String? description,
    String? counterparty,
  }) async {
    final payload = <String, dynamic>{
      'amount': _formatCurrency(amount),
      if (channel != null && channel.isNotEmpty) 'channel': channel,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      if (fee != null) 'fee': _formatCurrency(fee),
      if (description != null && description.isNotEmpty) 'description': description,
      if (counterparty != null && counterparty.isNotEmpty) 'counterparty': counterparty,
    };

    final response = await _apiClient.post('/api/transactions/deposit/', body: payload);
    if (response is! Map<String, dynamic>) {
      throw StateError('Unexpected response when processing deposit');
    }

    final result = WalletOperationResult.fromApi(response);
    _transactionService.recordRemoteTransaction(result.transaction);
    return result;
  }

  Future<WalletOperationResult> withdraw({
    required double amount,
    String status = 'pending',
    String? channel,
    String? reference,
    double? fee,
    String? description,
    String? counterparty,
    String? destination,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      'amount': _formatCurrency(amount),
      'status': status,
      if (channel != null && channel.isNotEmpty) 'channel': channel,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      if (fee != null) 'fee': _formatCurrency(fee),
      if (description != null && description.isNotEmpty) 'description': description,
      if (counterparty != null && counterparty.isNotEmpty) 'counterparty': counterparty,
      if (destination != null && destination.isNotEmpty) 'destination': destination,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    final response = await _apiClient.post('/api/transactions/withdraw/', body: payload);
    if (response is! Map<String, dynamic>) {
      throw StateError('Unexpected response when processing withdrawal');
    }

    final result = WalletOperationResult.fromApi(response);
    _transactionService.recordRemoteTransaction(result.transaction);
    return result;
  }
}
