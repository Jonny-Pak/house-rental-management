class AdminListingModel {
  final int id;
  final String title;
  final String description;
  final String? listingType;
  final double rentPrice;
  final double areaSqm;
  final String address;
  final String? ownerName;
  final String? ownerPhone;
  final String approvalStatus;
  final String? houseType;
  final String? legalDocuments;
  final String? createdAt;

  AdminListingModel({
    required this.id,
    required this.title,
    required this.description,
    this.listingType,
    required this.rentPrice,
    required this.areaSqm,
    required this.address,
    this.ownerName,
    this.ownerPhone,
    required this.approvalStatus,
    this.houseType,
    this.legalDocuments,
    this.createdAt,
  });

  factory AdminListingModel.fromJson(Map<String, dynamic> json) {
    return AdminListingModel(
      id: json['id'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      listingType: json['listingType'],
      rentPrice: (json['rentPrice'] ?? 0).toDouble(),
      areaSqm: (json['areaSqm'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      ownerName: json['ownerName'],
      ownerPhone: json['ownerPhone'],
      approvalStatus: json['approvalStatus'] ?? 'PENDING',
      houseType: json['houseType'],
      legalDocuments: json['legalDocuments'],
      createdAt: json['createdAt'],
    );
  }
}

