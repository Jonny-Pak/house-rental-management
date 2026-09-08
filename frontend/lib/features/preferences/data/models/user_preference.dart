class UserPreference {
  final double? minBudget;
  final double? maxBudget;
  final bool? hasPet;
  final String? preferredArea;

  const UserPreference({
    this.minBudget,
    this.maxBudget,
    this.hasPet,
    this.preferredArea,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      minBudget: (json['minBudget'] as num?)?.toDouble(),
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      hasPet: json['hasPet'] as bool?,
      preferredArea: json['preferredArea'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'minBudget': minBudget,
        'maxBudget': maxBudget,
        'hasPet': hasPet,
        'preferredArea': preferredArea,
      };
}
