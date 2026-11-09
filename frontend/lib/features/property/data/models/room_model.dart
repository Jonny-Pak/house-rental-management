class RoomModel {
  final int id;
  final int propertyId;
  final String name;
  final double area;
  final double price;
  final int maxCapacity;
  final String status;

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.area,
    required this.price,
    required this.maxCapacity,
    required this.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as int? ?? 0,
      propertyId: json['propertyId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      maxCapacity: json['maxCapacity'] as int? ?? 1,
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }
}
