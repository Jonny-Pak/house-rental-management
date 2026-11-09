import 'package:equatable/equatable.dart';

import '../../data/models/user_preference.dart';

enum PreferencesStatus {
  initial,
  loading,
  success,
  error,
  updating,
  updateSuccess,
}

class PreferencesState extends Equatable {
  const PreferencesState({
    this.status = PreferencesStatus.initial,
    this.currentPreference,
    this.interests = const [],
    this.errorMessage,
  });
  final PreferencesStatus status;
  final UserPreference? currentPreference;
  final List<String> interests;
  final String? errorMessage;

  PreferencesState copyWith({
    PreferencesStatus? status,
    UserPreference? currentPreference,
    List<String>? interests,
    String? errorMessage,
  }) => PreferencesState(
    status: status ?? this.status,
    currentPreference: currentPreference ?? this.currentPreference,
    interests: interests ?? this.interests,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    currentPreference,
    interests,
    errorMessage,
  ];
}
