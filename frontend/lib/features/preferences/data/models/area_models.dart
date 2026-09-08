class Province {
  final int id;
  final String name;
  final String code;

  const Province({required this.id, required this.name, required this.code});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class District {
  final int id;
  final String name;
  final String code;
  final int provinceId;

  const District({
    required this.id,
    required this.name,
    required this.code,
    required this.provinceId,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      provinceId: json['provinceId'] as int,
    );
  }
}

class Ward {
  final int id;
  final String name;
  final String code;
  final int districtId;

  const Ward({
    required this.id,
    required this.name,
    required this.code,
    required this.districtId,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      districtId: json['districtId'] as int,
    );
  }
}
