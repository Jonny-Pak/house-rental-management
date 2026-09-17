class PropertyModel {
  final int id;
  final String name;
  final String address;
  final String propertyType;
  final String description;
  final List<String> imageUrls;
  final double electricityPrice;
  final double waterPrice;
  final String status;
  final String? landlordName;
  final String? landlordPhone;

  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.propertyType,
    required this.description,
    required this.imageUrls,
    required this.electricityPrice,
    required this.waterPrice,
    required this.status,
    this.landlordName,
    this.landlordPhone,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      propertyType: json['propertyType'] as String? ?? 'BOARDING_HOUSE',
      description: json['description'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      electricityPrice: (json['electricityPrice'] as num?)?.toDouble() ?? 0.0,
      waterPrice: (json['waterPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'AVAILABLE',
      landlordName: json['landlordName'] as String?,
      landlordPhone: json['landlordPhone'] as String?,
    );
  }
}
