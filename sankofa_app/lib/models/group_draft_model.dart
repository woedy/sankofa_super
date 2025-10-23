class GroupDraftModel {
  const GroupDraftModel({
    required this.id,
    this.name,
    this.purpose,
    this.contributionAmount,
    this.frequency,
    this.startDate,
    this.memberNames = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? name;
  final String? purpose;
  final double? contributionAmount;
  final String? frequency;
  final DateTime? startDate;
  final List<String> memberNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupDraftModel copyWith({
    String? id,
    String? name,
    String? purpose,
    double? contributionAmount,
    String? frequency,
    DateTime? startDate,
    List<String>? memberNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupDraftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      memberNames: memberNames ?? this.memberNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purpose': purpose,
        'contributionAmount': contributionAmount,
        'frequency': frequency,
        'startDate': startDate?.toIso8601String(),
        'memberNames': memberNames,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GroupDraftModel.fromJson(Map<String, dynamic> json) => GroupDraftModel(
        id: json['id'] as String,
        name: json['name'] as String?,
        purpose: json['purpose'] as String?,
        contributionAmount: (json['contributionAmount'] as num?)?.toDouble(),
        frequency: json['frequency'] as String?,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : null,
        memberNames: json['memberNames'] != null
            ? List<String>.from(json['memberNames'] as List)
            : const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
