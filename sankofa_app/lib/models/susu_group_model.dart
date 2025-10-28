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
  final String? ownerId;
  final String ownerName;
  final bool ownedByPlatform;
  final bool isPublic;
  final String? description;
  final String? frequency;
  final String? location;
  final bool requiresApproval;
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
    this.ownerId,
    required this.ownerName,
    this.ownedByPlatform = false,
    this.isPublic = false,
    this.description,
    this.frequency,
    this.location,
    this.requiresApproval = false,
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
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownedByPlatform': ownedByPlatform,
    'isPublic': isPublic,
    'description': description,
    'frequency': frequency,
    'location': location,
    'requiresApproval': requiresApproval,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SusuGroupModel.fromJson(Map<String, dynamic> json) {
    final memberIdsRaw = (json['memberIds'] as List?) ?? const [];
    final memberNamesRaw = (json['memberNames'] as List?) ?? const [];
    final invitesRaw = (json['invites'] as List?) ?? const [];

    return SusuGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      memberIds: memberIdsRaw.map((value) => value.toString()).toList(),
      memberNames: memberNamesRaw.map((value) => value.toString()).toList(),
      invites: invitesRaw
          .whereType<Map>()
          .map((item) => GroupInviteModel.fromJson(item.cast<String, dynamic>()))
          .toList(),
      targetMemberCount:
          json['targetMemberCount'] as int? ?? memberNamesRaw.length,
      contributionAmount: _parseDouble(json['contributionAmount']),
      cycleNumber: json['cycleNumber'] as int? ?? 0,
      totalCycles: json['totalCycles'] as int? ?? 0,
      nextPayoutDate: DateTime.parse(json['nextPayoutDate'] as String),
      payoutOrder: json['payoutOrder'] as String,
      ownerId: json['ownerId']?.toString(),
      ownerName: (json['ownerName'] as String?)?.trim().isNotEmpty == true
          ? (json['ownerName'] as String)
          : 'Sankofa Platform',
      ownedByPlatform: json['ownedByPlatform'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? false,
      description: json['description'] as String?,
      frequency: json['frequency'] as String?,
      location: json['location'] as String?,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory SusuGroupModel.fromApi(Map<String, dynamic> json) =>
      SusuGroupModel.fromJson(json);

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

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
    String? ownerId,
    String? ownerName,
    bool? ownedByPlatform,
    bool? isPublic,
    String? description,
    String? frequency,
    String? location,
    bool? requiresApproval,
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
    ownerId: ownerId ?? this.ownerId,
    ownerName: ownerName ?? this.ownerName,
    ownedByPlatform: ownedByPlatform ?? this.ownedByPlatform,
    isPublic: isPublic ?? this.isPublic,
    description: description ?? this.description,
    frequency: frequency ?? this.frequency,
    location: location ?? this.location,
    requiresApproval: requiresApproval ?? this.requiresApproval,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
