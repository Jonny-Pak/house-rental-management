class MapListingModel {
  final int id;
  final String title;
  final double rentPrice;
  final double latitude;
  final double longitude;

  const MapListingModel({
    required this.id,
    required this.title,
    required this.rentPrice,
    required this.latitude,
    required this.longitude,
  });

  factory MapListingModel.fromJson(Map<String, dynamic> json) {
    return MapListingModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      rentPrice: (json['rentPrice'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Format rentPrice as a compact Vietnamese price tag.
  /// e.g. 5000000 → "5 Tr", 1500000 → "1.5 Tr", 800000 → "800 K"
  String get formattedPrice {
    if (rentPrice >= 1000000) {
      final millions = rentPrice / 1000000;
      final formatted = millions == millions.truncateToDouble()
          ? millions.toInt().toString()
          : millions.toStringAsFixed(1);
      return '$formatted Tr';
    } else if (rentPrice >= 1000) {
      final thousands = (rentPrice / 1000).round();
      return '$thousands K';
    }
    return rentPrice.toInt().toString();
  }
}
