import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_exception.dart';

class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();

  factory AuthService() => _instance;

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _accessExpiryKey = 'auth_access_expiry';
  static const String _userKey = 'current_user';

  final http.Client _httpClient = http.Client();

  Future<void> requestOtp(String phoneNumber, {String purpose = 'login'}) async {
    final uri = AppConfig.resolve('/api/auth/otp/request/');
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'phone_number': normalizePhone(phoneNumber),
        'purpose': purpose,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }
  }

  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String code,
    String purpose = 'login',
  }) async {
    final uri = AppConfig.resolve('/api/auth/otp/verify/');
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'phone_number': normalizePhone(phoneNumber),
        'code': code,
        'purpose': purpose,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final access = payload['access'] as String?;
    final refresh = payload['refresh'] as String?;
    final userJson = payload['user'] as Map<String, dynamic>?;

    if (access == null || refresh == null || userJson == null) {
      throw ApiException('Authentication response was missing required fields.');
    }

    final user = UserModel.fromApi(userJson);
    await _persistTokens(accessToken: access, refreshToken: refresh);
    await saveUser(user);
    return user;
  }

  Future<void> _persistTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_accessTokenKey, accessToken);
    final expiry = _decodeExpiry(accessToken);
    if (expiry != null) {
      await prefs.setInt(_accessExpiryKey, expiry.millisecondsSinceEpoch);
    }
  }

  Future<String?> getAccessToken({bool allowRefresh = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token == null) {
      return null;
    }
    if (!allowRefresh) {
      return token;
    }
    final expiryMillis = prefs.getInt(_accessExpiryKey);
    if (expiryMillis == null) {
      return token;
    }
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
    if (DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 45)))) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        return null;
      }
      return prefs.getString(_accessTokenKey);
    }
    return token;
  }

  Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final uri = AppConfig.resolve('/api/auth/token/refresh/');
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final access = payload['access'] as String?;
      if (access == null) {
        return false;
      }
      await _persistTokens(accessToken: access, refreshToken: refreshToken);
      return true;
    }

    await clearSession();
    return false;
  }

  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    final user = await getStoredUser();
    return user != null;
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userKey);
    return UserModel.tryParse(jsonString);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accessExpiryKey);
    await prefs.remove(_userKey);
  }

  String normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return input.trim();
    }
    if (digits.startsWith('233') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length == 10) {
      return '+233${digits.substring(1)}';
    }
    if (digits.length == 9) {
      return '+233$digits';
    }
    if (input.trim().startsWith('+')) {
      return input.trim();
    }
    return '+$digits';
  }

  DateTime? _decodeExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true).toLocal();
      }
      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true).toLocal();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
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
        // ignore
      }
    }

    return ApiException(message, statusCode: response.statusCode, details: details);
  }
}
