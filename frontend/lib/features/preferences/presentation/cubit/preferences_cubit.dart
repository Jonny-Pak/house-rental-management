import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../data/models/area_models.dart';
import '../../data/models/user_preference.dart';
import '../../data/repositories/area_repository.dart';
import '../../data/repositories/preference_repository.dart';
import 'preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  final AreaRepository _areaRepository;
  final PreferenceRepository _preferenceRepository;

  PreferencesCubit(this._areaRepository, this._preferenceRepository)
      : super(const PreferencesState());

  Future<void> loadInitialData() async {
    emit(state.copyWith(status: PreferencesStatus.loading));
    try {
      final futures = await Future.wait([
        _preferenceRepository.getPreferences(),
        _areaRepository.getProvinces(),
      ]);

      final userPref = futures[0] as UserPreference;
      final provinces = futures[1] as List<Province>;

      emit(state.copyWith(
        status: PreferencesStatus.success,
        currentPreference: userPref,
        provinces: provinces,
      ));
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Unknown error';
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: errorMsg));
    } catch (e) {
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> onProvinceChanged(Province province) async {
    emit(state.copyWith(
      selectedProvince: province,
      clearSelectedDistrict: true,
      clearSelectedWard: true,
      districts: [],
      wards: [],
    ));

    try {
      final districts = await _areaRepository.getDistricts(province.id);
      emit(state.copyWith(districts: districts));
    } catch (e) {
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: "Lỗi tải danh sách Quận/Huyện"));
    }
  }

  Future<void> onDistrictChanged(District district) async {
    emit(state.copyWith(
      selectedDistrict: district,
      clearSelectedWard: true,
      wards: [],
    ));

    try {
      final wards = await _areaRepository.getWards(district.id);
      emit(state.copyWith(wards: wards));
    } catch (e) {
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: "Lỗi tải danh sách Phường/Xã"));
    }
  }

  void onWardChanged(Ward ward) {
    emit(state.copyWith(selectedWard: ward));
  }

  Future<void> updatePreferences(double? minBudget, double? maxBudget, bool? hasPet) async {
    emit(state.copyWith(status: PreferencesStatus.updating));
    try {
      String? location;
      if (state.selectedProvince != null) {
        location = state.selectedProvince!.name;
        if (state.selectedDistrict != null) {
          location = "${state.selectedDistrict!.name}, $location";
          if (state.selectedWard != null) {
            location = "${state.selectedWard!.name}, $location";
          }
        }
      }

      final newPref = UserPreference(
        minBudget: minBudget,
        maxBudget: maxBudget,
        hasPet: hasPet,
        preferredArea: location ?? state.currentPreference?.preferredArea,
      );

      final updated = await _preferenceRepository.updatePreferences(newPref);
      emit(state.copyWith(
        status: PreferencesStatus.updateSuccess,
        currentPreference: updated,
      ));
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Update error';
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: errorMsg));
    } catch (e) {
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: e.toString()));
    }
  }
}
