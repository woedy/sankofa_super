class AppConfig {
  AppConfig._();

  static const String _envKey = 'SANKOFA_ENV';
  static const String _baseOverrideKey = 'API_BASE_URL';

  static const String _localBaseUrl = 'http://10.0.2.2:8000';
  static const String _stagingBaseUrl = 'https://staging.api.sankofa.local';
  static const String _productionBaseUrl = 'https://api.sankofa.africa';

  static String get environment => const String.fromEnvironment(_envKey, defaultValue: 'local');

  static String get apiBaseUrl {
    final override = const String.fromEnvironment(_baseOverrideKey);
    if (override.isNotEmpty) {
      return _normalize(override);
    }
    switch (environment) {
      case 'production':
        return _normalize(_productionBaseUrl);
      case 'staging':
        return _normalize(_stagingBaseUrl);
      default:
        return _normalize(_localBaseUrl);
    }
  }

  static Uri resolve(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(apiBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    final basePath = base.path
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');

    final joinedPath = [basePath, normalizedPath]
        .where((segment) => segment.isNotEmpty)
        .join('/');

    final params = _normalizeQueryParameters(queryParameters);

    return base.replace(
      path: joinedPath,
      queryParameters: params,
    );
  }

  static Map<String, String>? _normalizeQueryParameters(
    Map<String, dynamic>? source,
  ) {
    if (source == null || source.isEmpty) {
      return null;
    }

    final normalized = <String, String>{};
    source.forEach((key, value) {
      if (value == null) {
        return;
      }
      normalized[key] = value.toString();
    });

    return normalized.isEmpty ? null : normalized;
  }

  static String _normalize(String value) {
    var normalized = value.trim();
    if (!normalized.startsWith('http')) {
      normalized = 'https://$normalized';
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
