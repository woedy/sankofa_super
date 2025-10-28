class GroupInviteDraft {
  const GroupInviteDraft({
    required this.name,
    required this.phoneNumber,
    this.source,
  });

  final String name;
  final String phoneNumber;
  final String? source;

  GroupInviteDraft copyWith({
    String? name,
    String? phoneNumber,
    String? source,
  }) {
    return GroupInviteDraft(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        if (source != null) 'source': source,
      };

  factory GroupInviteDraft.fromJson(Map<String, dynamic> json) {
    return GroupInviteDraft(
      name: (json['name'] as String?)?.trim() ?? '',
      phoneNumber: (json['phoneNumber'] as String?)?.trim() ?? '',
      source: json['source'] as String?,
    );
  }
}

class GroupDraftModel {
  const GroupDraftModel({
    required this.id,
    this.name,
    this.purpose,
    this.contributionAmount,
    this.frequency,
    this.startDate,
    this.invites = const <GroupInviteDraft>[],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? name;
  final String? purpose;
  final double? contributionAmount;
  final String? frequency;
  final DateTime? startDate;
  final List<GroupInviteDraft> invites;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get memberNames => invites.map((invite) => invite.name).toList();

  GroupDraftModel copyWith({
    String? id,
    String? name,
    String? purpose,
    double? contributionAmount,
    String? frequency,
    DateTime? startDate,
    List<GroupInviteDraft>? invites,
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
      invites: invites ?? this.invites,
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
        'invites': invites.map((invite) => invite.toJson()).toList(),
        'memberNames': memberNames,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GroupDraftModel.fromJson(Map<String, dynamic> json) {
    final invitesJson = json['invites'];
    List<GroupInviteDraft> invites = const <GroupInviteDraft>[];

    if (invitesJson is List) {
      invites = invitesJson
          .whereType<Map>()
          .map((item) => GroupInviteDraft.fromJson(item.cast<String, dynamic>()))
          .where((invite) => invite.name.isNotEmpty || invite.phoneNumber.isNotEmpty)
          .toList();
    } else if (json['memberNames'] is List) {
      final legacyNames = List<String>.from(json['memberNames'] as List);
      invites = legacyNames
          .map(
            (name) => GroupInviteDraft(
              name: name,
              phoneNumber: '',
              source: 'legacy',
            ),
          )
          .toList();
    }

    return GroupDraftModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      purpose: json['purpose'] as String?,
      contributionAmount: (json['contributionAmount'] as num?)?.toDouble(),
      frequency: json['frequency'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      invites: invites,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
