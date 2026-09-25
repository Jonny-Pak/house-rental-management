class ContractModel {
  final int id;
  final int? listingId;
  final String? listingName;
  final int? landlordId;
  final String? landlordName;
  final int? tenantId;
  final String? tenantName;
  final String startDate;
  final String endDate;
  final double monthlyRent;
  final double depositAmount;
  final String status;
  final String? contractFileUrl;
  final String? createdAt;

  ContractModel({
    required this.id,
    this.listingId,
    this.listingName,
    this.landlordId,
    this.landlordName,
    this.tenantId,
    this.tenantName,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    this.contractFileUrl,
    this.createdAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>?;
    final landlord = json['landlord'] as Map<String, dynamic>?;
    final tenant = json['tenant'] as Map<String, dynamic>?;

    return ContractModel(
      id: json['id'] ?? json['contract_id'] ?? 0,
      listingId: listing?['id'] ?? json['listingId'],
      listingName: listing?['title'] ?? listing?['name'] ?? json['listingName'],
      landlordId: landlord?['userId'] ?? landlord?['id'] ?? json['landlordId'],
      landlordName: landlord?['fullName'] ?? json['landlordName'],
      tenantId: tenant?['userId'] ?? tenant?['id'] ?? json['tenantId'],
      tenantName: tenant?['fullName'] ?? json['tenantName'],
      startDate: json['startDate'] ?? json['start_date'] ?? '',
      endDate: json['endDate'] ?? json['end_date'] ?? '',
      monthlyRent: (json['monthlyRent'] ?? json['monthly_rent'] ?? 0).toDouble(),
      depositAmount: (json['depositAmount'] ?? json['deposit_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'ACTIVE',
      contractFileUrl: json['contractFileUrl'] ?? json['contract_file_url'],
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }
}

class CreateContractRequest {
  final int listingId;
  final int tenantId;
  final String startDate;
  final String endDate;
  final double monthlyRent;
  final double depositAmount;

  CreateContractRequest({
    required this.listingId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
  });

  Map<String, dynamic> toJson() => {
    'listingId': listingId,
    'tenantId': tenantId,
    'startDate': startDate,
    'endDate': endDate,
    'monthlyRent': monthlyRent,
    'depositAmount': depositAmount,
  };
}
