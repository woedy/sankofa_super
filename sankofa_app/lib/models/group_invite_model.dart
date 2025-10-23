enum GroupInviteStatus { pending, accepted, declined }

extension GroupInviteStatusX on GroupInviteStatus {
  String get key {
    switch (this) {
      case GroupInviteStatus.pending:
        return 'pending';
      case GroupInviteStatus.accepted:
        return 'accepted';
      case GroupInviteStatus.declined:
        return 'declined';
    }
  }

  static GroupInviteStatus fromKey(String? value) {
    for (final status in GroupInviteStatus.values) {
      if (status.key == value) {
        return status;
      }
    }
    return GroupInviteStatus.pending;
  }

  String get displayLabel {
    switch (this) {
      case GroupInviteStatus.pending:
        return 'Awaiting response';
      case GroupInviteStatus.accepted:
        return 'Accepted';
      case GroupInviteStatus.declined:
        return 'Declined';
    }
  }
}

class GroupInviteModel {
  const GroupInviteModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.status,
    required this.kycCompleted,
    required this.sentAt,
    this.respondedAt,
    this.lastRemindedAt,
    this.reminderCount = 0,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final GroupInviteStatus status;
  final bool kycCompleted;
  final DateTime sentAt;
  final DateTime? respondedAt;
  final DateTime? lastRemindedAt;
  final int reminderCount;

  GroupInviteModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    GroupInviteStatus? status,
    bool? kycCompleted,
    DateTime? sentAt,
    DateTime? respondedAt,
    DateTime? lastRemindedAt,
    int? reminderCount,
  }) {
    return GroupInviteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      kycCompleted: kycCompleted ?? this.kycCompleted,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      lastRemindedAt: lastRemindedAt ?? this.lastRemindedAt,
      reminderCount: reminderCount ?? this.reminderCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'status': status.key,
        'kycCompleted': kycCompleted,
        'sentAt': sentAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'lastRemindedAt': lastRemindedAt?.toIso8601String(),
        'reminderCount': reminderCount,
      };

  factory GroupInviteModel.fromJson(Map<String, dynamic> json) {
    return GroupInviteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      status: GroupInviteStatusX.fromKey(json['status'] as String?),
      kycCompleted: json['kycCompleted'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      lastRemindedAt: json['lastRemindedAt'] != null
          ? DateTime.parse(json['lastRemindedAt'] as String)
          : null,
      reminderCount: json['reminderCount'] as int? ?? 0,
    );
  }
}
