class DisputeMessageModel {
  DisputeMessageModel({
    required this.id,
    required this.authorName,
    required this.role,
    required this.channel,
    required this.message,
    required this.timestamp,
    required this.isInternal,
  });

  factory DisputeMessageModel.fromApi(Map<String, dynamic> json) {
    return DisputeMessageModel(
      id: json['id']?.toString() ?? '',
      authorName: (json['author_name'] as String?)?.trim(),
      role: json['role'] as String? ?? 'Member',
      channel: (json['channel'] as String?)?.trim() ?? '',
      message: json['message'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isInternal: json['is_internal'] as bool? ?? false,
    );
  }

  final String id;
  final String? authorName;
  final String role;
  final String channel;
  final String message;
  final DateTime timestamp;
  final bool isInternal;

  bool get isMember => role.toLowerCase() == 'member';

  bool get isSupport => !isMember;
}
