const areaTypes = <String, String>{
  'PROVINCE': 'Tỉnh / thành phố',
  'WARD': 'Phường',
  'COMMUNE': 'Xã',
  'SPECIAL': 'Đặc khu',
  'DISTRICT': 'Quận / huyện (cũ)',
};

class AdminArea {
  const AdminArea({
    required this.id,
    required this.name,
    required this.type,
    required this.code,
    this.parentId,
    this.parentName,
    this.active = true,
    this.children = 0,
    this.listingCount = 0,
    this.propertyCount = 0,
  });
  final int id;
  final String name, type, code;
  final int? parentId;
  final String? parentName;
  final bool active;
  final int children, listingCount, propertyCount;
  String get typeLabel => areaTypes[type] ?? type;
  bool get used => children > 0 || listingCount > 0 || propertyCount > 0;

  factory AdminArea.fromJson(Map<String, dynamic> json) => AdminArea(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    type: json['type'] as String,
    code: json['code'] as String? ?? '',
    parentId: (json['parentId'] as num?)?.toInt(),
    parentName: json['parentName'] as String?,
    active: json['active'] == true,
    children: (json['children'] as num).toInt(),
    listingCount: (json['listingCount'] as num).toInt(),
    propertyCount: (json['propertyCount'] as num).toInt(),
  );
}

class AdminAreaPage {
  const AdminAreaPage(this.items, this.total, this.page, this.totalPages);
  final List<AdminArea> items;
  final int total, page, totalPages;
  factory AdminAreaPage.fromJson(Map<String, dynamic> json) => AdminAreaPage(
    (json['items'] as List)
        .map((row) => AdminArea.fromJson(Map<String, dynamic>.from(row)))
        .toList(),
    (json['total'] as num).toInt(),
    (json['page'] as num).toInt(),
    (json['totalPages'] as num).toInt(),
  );
}
