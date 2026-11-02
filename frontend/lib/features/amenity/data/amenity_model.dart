class Amenity {
  const Amenity({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.active = true,
    this.version = 0,
    this.listingCount = 0,
  });
  final int id, version, listingCount;
  final String name, category, description;
  final bool active;
  String get categoryLabel => category == 'FURNITURE' ? 'Nội thất' : 'Tiện ích';
  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    category: json['category'] as String,
    description: json['description'] as String? ?? '',
    active: json['active'] != false,
    version: (json['version'] as num?)?.toInt() ?? 0,
    listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
  );
}

class AmenityPageData {
  AmenityPageData(Map<String, dynamic> json)
    : items = [
        for (final item in json['items'] as List)
          Amenity.fromJson(Map<String, dynamic>.from(item)),
      ],
      total = (json['total'] as num).toInt(),
      page = (json['page'] as num).toInt(),
      totalPages = (json['totalPages'] as num).toInt();
  final List<Amenity> items;
  final int total, page, totalPages;
}
