import 'package:equatable/equatable.dart';

class RoommateInfo extends Equatable {
  const RoommateInfo({
    this.currentOccupants = 1,
    this.maxOccupants = 2,
    this.genderPreference = 'ANY',
    this.allowPets = false,
    this.allowSmoking = false,
    this.roommateRequirements = '',
  });
  final int currentOccupants, maxOccupants;
  final String genderPreference, roommateRequirements;
  final bool allowPets, allowSmoking;

  factory RoommateInfo.fromJson(Map<String, dynamic> json) => RoommateInfo(
    currentOccupants: (json['currentOccupants'] as num?)?.toInt() ?? 1,
    maxOccupants: (json['maxOccupants'] as num?)?.toInt() ?? 2,
    genderPreference: json['genderPreference'] as String? ?? 'ANY',
    allowPets: json['allowPets'] == true,
    allowSmoking: json['allowSmoking'] == true,
    roommateRequirements: json['roommateRequirements'] as String? ?? '',
  );

  bool get isValid =>
      currentOccupants >= 0 &&
      maxOccupants <= 20 &&
      maxOccupants > currentOccupants &&
      ['ANY', 'MALE', 'FEMALE'].contains(genderPreference) &&
      roommateRequirements.length <= 500;
  int get availableSlots => maxOccupants - currentOccupants;
  String get genderLabel => switch (genderPreference) {
    'MALE' => 'Nam',
    'FEMALE' => 'Nữ',
    _ => 'Không yêu cầu',
  };

  RoommateInfo copyWith({
    int? currentOccupants,
    int? maxOccupants,
    String? genderPreference,
    bool? allowPets,
    bool? allowSmoking,
    String? roommateRequirements,
  }) => RoommateInfo(
    currentOccupants: currentOccupants ?? this.currentOccupants,
    maxOccupants: maxOccupants ?? this.maxOccupants,
    genderPreference: genderPreference ?? this.genderPreference,
    allowPets: allowPets ?? this.allowPets,
    allowSmoking: allowSmoking ?? this.allowSmoking,
    roommateRequirements: roommateRequirements ?? this.roommateRequirements,
  );

  Map<String, dynamic> toJson() => {
    'currentOccupants': currentOccupants,
    'maxOccupants': maxOccupants,
    'genderPreference': genderPreference,
    'allowPets': allowPets,
    'allowSmoking': allowSmoking,
    'roommateRequirements': roommateRequirements.trim(),
  };

  @override
  List<Object?> get props => [
    currentOccupants,
    maxOccupants,
    genderPreference,
    allowPets,
    allowSmoking,
    roommateRequirements,
  ];
}
