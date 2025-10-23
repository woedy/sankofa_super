import 'group_invite_model.dart';

class SusuGroupModel {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<String> memberNames;
  final List<GroupInviteModel> invites;
  final int targetMemberCount;
  final double contributionAmount;
  final int cycleNumber;
  final int totalCycles;
  final DateTime nextPayoutDate;
  final String payoutOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  SusuGroupModel({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.memberNames,
    required this.invites,
    required this.targetMemberCount,
    required this.contributionAmount,
    required this.cycleNumber,
    required this.totalCycles,
    required this.nextPayoutDate,
    required this.payoutOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberIds': memberIds,
    'memberNames': memberNames,
    'invites': invites.map((invite) => invite.toJson()).toList(),
    'targetMemberCount': targetMemberCount,
    'contributionAmount': contributionAmount,
    'cycleNumber': cycleNumber,
    'totalCycles': totalCycles,
    'nextPayoutDate': nextPayoutDate.toIso8601String(),
    'payoutOrder': payoutOrder,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SusuGroupModel.fromJson(Map<String, dynamic> json) => SusuGroupModel(
    id: json['id'] as String,
    name: json['name'] as String,
    memberIds: List<String>.from(json['memberIds'] as List),
    memberNames: List<String>.from(json['memberNames'] as List),
    invites: (json['invites'] as List?)
            ?.map((item) =>
                GroupInviteModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        const [],
    targetMemberCount:
        json['targetMemberCount'] as int? ?? List<String>.from(json['memberNames'] as List).length,
    contributionAmount: (json['contributionAmount'] as num).toDouble(),
    cycleNumber: json['cycleNumber'] as int,
    totalCycles: json['totalCycles'] as int,
    nextPayoutDate: DateTime.parse(json['nextPayoutDate'] as String),
    payoutOrder: json['payoutOrder'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  SusuGroupModel copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    List<String>? memberNames,
    List<GroupInviteModel>? invites,
    int? targetMemberCount,
    double? contributionAmount,
    int? cycleNumber,
    int? totalCycles,
    DateTime? nextPayoutDate,
    String? payoutOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SusuGroupModel(
    id: id ?? this.id,
    name: name ?? this.name,
    memberIds: memberIds ?? this.memberIds,
    memberNames: memberNames ?? this.memberNames,
    invites: invites ?? this.invites,
    targetMemberCount: targetMemberCount ?? this.targetMemberCount,
    contributionAmount: contributionAmount ?? this.contributionAmount,
    cycleNumber: cycleNumber ?? this.cycleNumber,
    totalCycles: totalCycles ?? this.totalCycles,
    nextPayoutDate: nextPayoutDate ?? this.nextPayoutDate,
    payoutOrder: payoutOrder ?? this.payoutOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
