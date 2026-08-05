enum UserRole {
  customer('CUSTOMER', 'Customer'),
  vendor('VENDOR', 'Vendor Studio Partner'),
  admin('ADMIN', 'Platform Administrator');

  final String code;
  final String title;

  const UserRole(this.code, this.title);

  static UserRole fromCode(String? code) {
    return UserRole.values.firstWhere(
      (role) => role.code.toUpperCase() == code?.toUpperCase(),
      orElse: () => UserRole.customer,
    );
  }
}

class UserModel {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final String? avatarUrl;
  final String? studioStatus; // PENDING, APPROVED, REJECTED, SUSPENDED (for vendors)
  final String? rejectionReason;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.email = '',
    required this.role,
    this.isVerified = true,
    this.isActive = true,
    this.avatarUrl,
    this.studioStatus,
    this.rejectionReason,
  });

  bool get isApprovedVendor => role == UserRole.vendor && studioStatus == 'APPROVED';
  bool get isPendingVendor => role == UserRole.vendor && (studioStatus == 'PENDING' || studioStatus == null);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? 'HER AREA User',
      email: json['email'] ?? '',
      role: UserRole.fromCode(json['role']?.toString()),
      isVerified: json['is_verified'] ?? true,
      isActive: json['is_active'] ?? true,
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      studioStatus: json['studio_status'] ?? json['status'],
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'email': email,
      'role': role.code,
      'is_verified': isVerified,
      'is_active': isActive,
      'avatar_url': avatarUrl,
      'studio_status': studioStatus,
      'rejection_reason': rejectionReason,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    bool? isVerified,
    String? avatarUrl,
    String? studioStatus,
    String? rejectionReason,
  }) {
    return UserModel(
      id: id,
      phoneNumber: phoneNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      studioStatus: studioStatus ?? this.studioStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
