import 'package:equatable/equatable.dart';
import '../../data/models/area_models.dart';
import '../../data/models/user_preference.dart';

enum PreferencesStatus { initial, loading, success, error, updating, updateSuccess }

class PreferencesState extends Equatable {
  final PreferencesStatus status;
  final UserPreference? currentPreference;
  final List<Province> provinces;
  final List<District> districts;
  final List<Ward> wards;
  final Province? selectedProvince;
  final District? selectedDistrict;
  final Ward? selectedWard;
  final String? errorMessage;

  const PreferencesState({
    this.status = PreferencesStatus.initial,
    this.currentPreference,
    this.provinces = const [],
    this.districts = const [],
    this.wards = const [],
    this.selectedProvince,
    this.selectedDistrict,
    this.selectedWard,
    this.errorMessage,
  });

  PreferencesState copyWith({
    PreferencesStatus? status,
    UserPreference? currentPreference,
    List<Province>? provinces,
    List<District>? districts,
    List<Ward>? wards,
    Province? selectedProvince,
    District? selectedDistrict,
    Ward? selectedWard,
    String? errorMessage,
    bool clearSelectedProvince = false,
    bool clearSelectedDistrict = false,
    bool clearSelectedWard = false,
  }) {
    return PreferencesState(
      status: status ?? this.status,
      currentPreference: currentPreference ?? this.currentPreference,
      provinces: provinces ?? this.provinces,
      districts: districts ?? this.districts,
      wards: wards ?? this.wards,
      selectedProvince: clearSelectedProvince ? null : (selectedProvince ?? this.selectedProvince),
      selectedDistrict: clearSelectedDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
      selectedWard: clearSelectedWard ? null : (selectedWard ?? this.selectedWard),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentPreference,
        provinces,
        districts,
        wards,
        selectedProvince,
        selectedDistrict,
        selectedWard,
        errorMessage,
      ];
}
