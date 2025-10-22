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
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        amount: (json['amount'] as num).toDouble(),
        channel: json['channel'] as String,
        note: json['note'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}
