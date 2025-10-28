class WalletSnapshot {
  const WalletSnapshot({
    required this.id,
    required this.balance,
    required this.updatedAt,
    required this.currency,
    this.isPlatform = false,
  });

  final String id;
  final double balance;
  final DateTime updatedAt;
  final String currency;
  final bool isPlatform;

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) => WalletSnapshot(
        id: json['id'] as String,
        balance: _parseDouble(json['balance']),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        currency: (json['currency'] as String?) ?? 'GHS',
        isPlatform: _parseBool(json['is_platform'] ?? json['isPlatform']),
      );

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
