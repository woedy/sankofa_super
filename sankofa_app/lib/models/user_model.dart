import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final String kycStatus;
  final double walletBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.kycStatus,
    this.walletBalance = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'photoUrl': photoUrl,
    'kycStatus': kycStatus,
    'walletBalance': walletBalance,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
        kycStatus: json['kycStatus'] as String,
        walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  factory UserModel.fromApi(Map<String, dynamic> json) {
    final fullName = (json['full_name'] as String?)?.trim();
    final phone = json['phone_number'] as String? ?? '';
    final createdAtRaw = json['date_joined'] as String? ?? DateTime.now().toIso8601String();
    final updatedAtRaw = json['updated_at'] as String? ?? createdAtRaw;
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: fullName?.isNotEmpty == true ? fullName! : phone,
      phone: phone,
      email: json['email'] as String? ?? '',
      photoUrl: json['avatar'] as String?,
      kycStatus: json['kyc_status'] as String? ?? 'pending',
      walletBalance: _parseDouble(json['wallet_balance']),
      createdAt: DateTime.parse(createdAtRaw),
      updatedAt: DateTime.parse(updatedAtRaw),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    String? kycStatus,
    double? walletBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        kycStatus: kycStatus ?? this.kycStatus,
        walletBalance: walletBalance ?? this.walletBalance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static UserModel? tryParse(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
