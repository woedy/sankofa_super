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
    required this.walletBalance,
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
    walletBalance: (json['walletBalance'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

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
}
