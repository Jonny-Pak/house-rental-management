class MembershipPackage {
  final int id;
  final String packageName;
  final double price;
  final int standardPostQuota;
  final int vipPostQuota;
  final int refreshQuota;
  final String? description;

  MembershipPackage({
    required this.id,
    required this.packageName,
    required this.price,
    required this.standardPostQuota,
    required this.vipPostQuota,
    required this.refreshQuota,
    this.description,
  });

  factory MembershipPackage.fromJson(Map<String, dynamic> json) {
    return MembershipPackage(
      id: json['id'] as int,
      packageName: json['packageName'] as String,
      price: (json['price'] as num).toDouble(),
      standardPostQuota: json['standardPostQuota'] as int,
      vipPostQuota: json['vipPostQuota'] as int,
      refreshQuota: json['refreshQuota'] as int,
      description: json['description'] as String?,
    );
  }
}