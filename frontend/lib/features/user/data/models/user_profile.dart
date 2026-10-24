class UserProfile {
  final int id;
  final List<String> interests;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? role;
  final String? status;
  final String? membershipPackageName, subscriptionStatus;
  final int? remainingStandardQuota, remainingVipQuota, remainingRefreshQuota;

  const UserProfile({
    required this.id,
    this.interests = const [],
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.role,
    this.status,
    this.membershipPackageName,
    this.subscriptionStatus,
    this.remainingStandardQuota,
    this.remainingVipQuota,
    this.remainingRefreshQuota,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      membershipPackageName: json['membershipPackageName'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      remainingStandardQuota: (json['remainingStandardQuota'] as num?)?.toInt(),
      remainingVipQuota: (json['remainingVipQuota'] as num?)?.toInt(),
      remainingRefreshQuota: (json['remainingRefreshQuota'] as num?)?.toInt(),
    );
  }

  UserProfile withInterests(List<String> selected) => UserProfile(
    id: id,
    interests: List.of(selected),
    fullName: fullName,
    email: email,
    phoneNumber: phoneNumber,
    avatarUrl: avatarUrl,
    role: role,
    status: status,
    membershipPackageName: membershipPackageName,
    subscriptionStatus: subscriptionStatus,
    remainingStandardQuota: remainingStandardQuota,
    remainingVipQuota: remainingVipQuota,
    remainingRefreshQuota: remainingRefreshQuota,
  );
}
