import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class UserService {
  UserService({ApiClient? apiClient, AuthService? authService})
      : _authService = authService ?? AuthService(),
        _apiClient = apiClient ?? ApiClient(authService: authService ?? AuthService());

  final AuthService _authService;
  final ApiClient _apiClient;

  Future<UserModel?> getCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final stored = await _authService.getStoredUser();
      if (stored != null) {
        return stored;
      }
    }

    final response = await _apiClient.get('/api/auth/me/');
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromApi(response);
      await _authService.saveUser(user);
      return user;
    }
    return null;
  }

  Future<UserModel?> refreshCurrentUser() => getCurrentUser(forceRefresh: true);

  Future<void> saveUser(UserModel user) => _authService.saveUser(user);

  Future<void> updateKycStatus(String status) async {
    final user = await getCurrentUser();
    if (user == null) {
      return;
    }
    final updated = user.copyWith(kycStatus: status, updatedAt: DateTime.now());
    await _authService.saveUser(updated);
  }

  Future<void> updateWalletBalance(double newBalance, {DateTime? walletUpdatedAt, DateTime? userUpdatedAt}) async {
    final user = await getCurrentUser();
    if (user == null) {
      return;
    }
    final now = DateTime.now();
    final updated = user.copyWith(
      walletBalance: newBalance,
      walletUpdatedAt: walletUpdatedAt ?? now,
      updatedAt: userUpdatedAt ?? now,
    );
    await _authService.saveUser(updated);
  }

  Future<void> clearSession() => _authService.clearSession();
}
