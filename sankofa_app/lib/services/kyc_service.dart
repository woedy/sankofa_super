import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class KycService {
  KycService({ApiClient? apiClient, AuthService? authService})
      : _authService = authService ?? AuthService(),
        _apiClient = apiClient ?? ApiClient(authService: authService ?? AuthService());

  final AuthService _authService;
  final ApiClient _apiClient;

  Future<UserModel> uploadGhanaCard({
    required XFile frontImage,
    required XFile backImage,
  }) async {
    final files = <http.MultipartFile>[
      await _toMultipart('front_image', frontImage),
      await _toMultipart('back_image', backImage),
    ];

    final response = await _apiClient.postMultipart(
      '/api/auth/ghana-card/',
      files: files,
    );

    if (response is Map<String, dynamic>) {
      final userJson = response['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        final user = UserModel.fromApi(userJson);
        await _authService.saveUser(user);
        return user;
      }
      final message = response['message'] as String?;
      throw ApiException(message ?? 'We could not submit your identification.');
    }

    throw ApiException('We could not submit your identification.');
  }

  Future<http.MultipartFile> _toMultipart(String fieldName, XFile file) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : '$fieldName.jpg';
    final mediaType = _guessMediaType(filename);

    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
      contentType: mediaType,
    );
  }

  MediaType _guessMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.heic')) {
      return MediaType('image', 'heic');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
