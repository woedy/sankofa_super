import 'dispute_attachment_model.dart';
import 'dispute_message_model.dart';

class DisputeModel {
  DisputeModel({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.severity,
    required this.priority,
    required this.category,
    required this.channel,
    required this.openedAt,
    required this.lastUpdated,
    required this.slaStatus,
    this.groupId,
    this.groupName,
    this.assignedToId,
    this.assignedToName,
    this.slaDue,
    this.resolutionNotes,
    this.relatedArticleId,
    this.relatedArticleTitle,
    this.messages = const [],
    this.attachments = const [],
  });

  factory DisputeModel.fromApi(Map<String, dynamic> json) {
    final messagesJson = json['messages'];
    final attachmentsJson = json['attachments'];
    final rawId = json['id'];
    final id = rawId == null ? '' : rawId.toString();
    if (id.isEmpty) {
      throw const FormatException('Missing dispute identifier');
    }
    return DisputeModel(
      id: id,
      caseNumber: json['case_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      severity: json['severity'] as String? ?? 'Medium',
      priority: json['priority'] as String? ?? 'Medium',
      category: json['category'] as String? ?? '',
      channel: json['channel'] as String? ?? 'Mobile App',
      openedAt: DateTime.tryParse(json['opened_at'] as String? ?? '') ?? DateTime.now(),
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
      slaStatus: json['sla_status'] as String? ?? 'On Track',
      groupId: json['group_id']?.toString(),
      groupName: json['group_name'] as String?,
      assignedToId: json['assigned_to_id']?.toString(),
      assignedToName: json['assigned_to_name'] as String?,
      slaDue: DateTime.tryParse(json['sla_due'] as String? ?? ''),
      resolutionNotes: json['resolution_notes'] as String?,
      relatedArticleId: json['related_article_id']?.toString(),
      relatedArticleTitle: (json['related_article'] as Map<String, dynamic>?)?['title'] as String?,
      messages: messagesJson is List
          ? messagesJson
              .whereType<Map<String, dynamic>>()
              .map(DisputeMessageModel.fromApi)
              .toList()
          : const <DisputeMessageModel>[],
      attachments: attachmentsJson is List
          ? attachmentsJson
              .whereType<Map<String, dynamic>>()
              .map(DisputeAttachmentModel.fromApi)
              .toList()
          : const <DisputeAttachmentModel>[],
    );
  }

  final String id;
  final String caseNumber;
  final String title;
  final String description;
  final String status;
  final String severity;
  final String priority;
  final String category;
  final String channel;
  final DateTime openedAt;
  final DateTime lastUpdated;
  final String slaStatus;
  final String? groupId;
  final String? groupName;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime? slaDue;
  final String? resolutionNotes;
  final String? relatedArticleId;
  final String? relatedArticleTitle;
  final List<DisputeMessageModel> messages;
  final List<DisputeAttachmentModel> attachments;

  DisputeModel copyWith({
    String? id,
    String? caseNumber,
    String? title,
    String? description,
    String? status,
    String? severity,
    String? priority,
    String? category,
    String? channel,
    DateTime? openedAt,
    DateTime? lastUpdated,
    String? slaStatus,
    String? groupId,
    String? groupName,
    String? assignedToId,
    String? assignedToName,
    DateTime? slaDue,
    String? resolutionNotes,
    String? relatedArticleId,
    String? relatedArticleTitle,
    List<DisputeMessageModel>? messages,
    List<DisputeAttachmentModel>? attachments,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      channel: channel ?? this.channel,
      openedAt: openedAt ?? this.openedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      slaStatus: slaStatus ?? this.slaStatus,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      slaDue: slaDue ?? this.slaDue,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      relatedArticleId: relatedArticleId ?? this.relatedArticleId,
      relatedArticleTitle: relatedArticleTitle ?? this.relatedArticleTitle,
      messages: messages ?? this.messages,
      attachments: attachments ?? this.attachments,
    );
  }
}
