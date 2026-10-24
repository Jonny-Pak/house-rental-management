class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.verified,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String role;
  final String status;
  final bool verified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'ADMIN';
  bool get locked => status == 'LOCKED';
  String get roleLabel => isAdmin ? 'Admin' : 'Member';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    role: json['role'] as String,
    status: json['status'] as String,
    verified: json['verified'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
  );
}

class AdminUserPage {
  const AdminUserPage(this.items, this.total, this.page, this.totalPages);
  final List<AdminUser> items;
  final int total;
  final int page;
  final int totalPages;

  factory AdminUserPage.fromJson(Map<String, dynamic> json) => AdminUserPage(
    (json['items'] as List)
        .map((row) => AdminUser.fromJson(Map<String, dynamic>.from(row)))
        .toList(),
    (json['total'] as num).toInt(),
    (json['page'] as num).toInt(),
    (json['totalPages'] as num).toInt(),
  );
}
