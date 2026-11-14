class SubscriptionBenefits {
  const SubscriptionBenefits({
    this.packageId,
    required this.packageName,
    required this.status,
    required this.standard,
    required this.vip,
    required this.refresh,
    this.expiresAt,
  });
  final int? packageId;
  final String packageName, status;
  final int standard, vip, refresh;
  final DateTime? expiresAt;

  factory SubscriptionBenefits.fromJson(Map<String, dynamic> json) =>
      SubscriptionBenefits(
        packageId: (json['packageId'] as num?)?.toInt(),
        packageName: json['packageName'] as String? ?? 'Gói dịch vụ',
        status: json['status'] as String? ?? 'EXPIRED',
        standard: (json['standard'] as num?)?.toInt() ?? 0,
        vip: (json['vip'] as num?)?.toInt() ?? 0,
        refresh: (json['refresh'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      );
}
