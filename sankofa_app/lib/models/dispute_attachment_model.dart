import 'package:intl/intl.dart';

class DisputeAttachmentModel {
  DisputeAttachmentModel({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.uploadedAt,
    required this.downloadUrl,
  });

  factory DisputeAttachmentModel.fromApi(Map<String, dynamic> json) {
    return DisputeAttachmentModel(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name'] as String? ?? 'Attachment',
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploaded_at'] as String? ?? '') ?? DateTime.now(),
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }

  final String id;
  final String fileName;
  final String contentType;
  final int size;
  final DateTime uploadedAt;
  final String downloadUrl;

  String get formattedSize {
    if (size <= 0) {
      return 'Unknown size';
    }
    if (size < 1024) {
      return '${size} B';
    }
    if (size < 1024 * 1024) {
      final kb = size / 1024;
      return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
    }
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 1 : 2)} MB';
  }

  String formattedUploadedAt([DateFormat? format]) {
    final formatter = format ?? DateFormat('MMM d, yyyy • h:mm a');
    return formatter.format(uploadedAt);
  }
}
