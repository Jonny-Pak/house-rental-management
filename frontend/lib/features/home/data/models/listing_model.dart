class Listing {
  final int id;
  final String title;
  final String? description;
  final String? listingType;
  final double rentPrice;
  final double areaSqm;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? houseType;

  Listing({
    required this.id,
    required this.title,
    this.description,
    this.listingType,
    required this.rentPrice,
    required this.areaSqm,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.houseType,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      listingType: json['listingType'] as String?,
      rentPrice: (json['rentPrice'] as num?)?.toDouble() ?? 0.0,
      areaSqm: (json['areaSqm'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      houseType: json['houseType'] as String?,
    );
  }
}

