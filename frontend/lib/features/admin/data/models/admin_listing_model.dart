import '../../../listing/data/models/roommate_info.dart';

class AdminListingModel {
  final RoommateInfo? roommateInfo;
  final List<String> imageUrls;
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
    this.imageUrls = const [],
    this.roommateInfo,
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
      roommateInfo: json['listingType'] == 'SHARED_ROOM'
          ? RoommateInfo.fromJson(json)
          : null,
      imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [],
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      listingType: json['listingType']?.toString(),
      rentPrice: (json['rentPrice'] as num?)?.toDouble() ?? 0.0,
      areaSqm: (json['areaSqm'] as num?)?.toDouble() ?? 0.0,
      address: json['address']?.toString() ?? '',
      ownerName: json['ownerName']?.toString(),
      ownerPhone: json['ownerPhone']?.toString(),
      approvalStatus: json['approvalStatus']?.toString() ?? 'PENDING',
      houseType: json['houseType']?.toString(),
      legalDocuments: json['legalDocuments']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
