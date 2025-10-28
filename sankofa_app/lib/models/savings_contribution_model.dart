class SavingsContributionModel {
  final String id;
  final String goalId;
  final double amount;
  final String channel;
  final String note;
  final DateTime date;

  SavingsContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.channel,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'channel': channel,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory SavingsContributionModel.fromJson(Map<String, dynamic> json) =>
      SavingsContributionModel(
        id: json['id']?.toString() ?? '',
        goalId: json['goalId']?.toString() ?? '',
        amount: _parseDouble(json['amount']),
        channel: json['channel'] as String,
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );

  factory SavingsContributionModel.fromApi(Map<String, dynamic> json) =>
      SavingsContributionModel.fromJson(json);

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
