class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'ApiException($message, status: $statusCode, details: $details)';
}
