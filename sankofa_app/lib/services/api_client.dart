import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, AuthService? authService})
      : _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? AuthService();

  final http.Client _httpClient;
  final AuthService _authService;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    final uri = AppConfig.resolve(path, queryParameters);
    return _request('GET', uri);
  }

  Future<dynamic> post(String path, {Object? body}) {
    final uri = AppConfig.resolve(path);
    return _request('POST', uri, body: body);
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) {
    final uri = AppConfig.resolve(path);
    return _multipartRequest('POST', uri, fields: fields, files: files);
  }

  static const Duration _defaultTimeout = Duration(seconds: 20);

  Future<dynamic> _request(
    String method,
    Uri uri, {
    Object? body,
    bool retrying = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    final accessToken = await _authService.getAccessToken(allowRefresh: false);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    http.Response response;
    final payload = body == null
        ? null
        : body is String
            ? body
            : jsonEncode(body);

    try {
      switch (method) {
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: payload)
              .timeout(_defaultTimeout);
          break;
        case 'GET':
        default:
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(_defaultTimeout);
      }
    } on TimeoutException {
      throw ApiException(
        'The request timed out. Please check your connection and try again.',
      );
    } on SocketException catch (error) {
      throw ApiException(
        'Unable to reach the server. Please check your internet connection.',
        details: {'reason': error.message},
      );
    } on http.ClientException catch (error) {
      throw ApiException('Unable to reach the server. Please try again.', details: {'reason': error.message});
    }

    if (response.statusCode == 401) {
      final shouldRetry = !retrying && await _authService.refreshAccessToken();
      if (shouldRetry) {
        return _request(method, uri, body: body, retrying: true);
      }
      throw ApiException('Your session has expired. Please sign in again.', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return response.body;
    }
  }

  Future<dynamic> _multipartRequest(
    String method,
    Uri uri, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool retrying = false,
  }) async {
    final request = http.MultipartRequest(method, uri);
    request.headers['Accept'] = 'application/json';

    final accessToken = await _authService.getAccessToken(allowRefresh: false);
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(_defaultTimeout);
    } on TimeoutException {
      throw ApiException(
        'The request timed out. Please check your connection and try again.',
      );
    } on SocketException catch (error) {
      throw ApiException(
        'Unable to reach the server. Please check your internet connection.',
        details: {'reason': error.message},
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        'Unable to reach the server. Please try again.',
        details: {'reason': error.message},
      );
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      final shouldRetry = !retrying && await _authService.refreshAccessToken();
      if (shouldRetry) {
        return _multipartRequest(method, uri, fields: fields, files: files, retrying: true);
      }
      throw ApiException('Your session has expired. Please sign in again.', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    if (response.bodyBytes.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return response.body;
    }
  }

  ApiException _buildException(http.Response response) {
    Map<String, dynamic>? details;
    String message = 'Request failed with status ${response.statusCode}.';

    if (response.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          details = decoded;
          final detail = decoded['detail'] ?? decoded['message'];
          if (detail is String && detail.isNotEmpty) {
            message = detail;
          }
        }
      } catch (_) {
        // ignore parse errors
      }
    }

    return ApiException(message, statusCode: response.statusCode, details: details);
  }
}
