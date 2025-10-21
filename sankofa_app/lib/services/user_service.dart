import 'package:sankofasave/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserService {
  static const String _userKey = 'current_user';

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserModel.fromJson(json.decode(userJson));
    }
    return _getDefaultUser();
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> updateKycStatus(String status) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(
        kycStatus: status,
        updatedAt: DateTime.now(),
      );
      await saveUser(updatedUser);
    }
  }

  Future<void> updateWalletBalance(double newBalance) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(
        walletBalance: newBalance,
        updatedAt: DateTime.now(),
      );
      await saveUser(updatedUser);
    }
  }

  UserModel _getDefaultUser() => UserModel(
    id: 'user_001',
    name: 'Kwame Mensah',
    phone: '+233 24 123 4567',
    email: 'kwame.mensah@example.com',
    photoUrl: 'assets/images/African_man_business_null_1760947790305.jpg',
    kycStatus: 'verified',
    walletBalance: 2450.00,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now(),
  );
}
