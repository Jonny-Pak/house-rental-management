import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_preference.dart';
import '../../data/repositories/preference_repository.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import 'preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit(this._repository) : super(const PreferencesState());
  final PreferenceRepository _repository;

  Future<void> loadInitialData() async {
    emit(state.copyWith(status: PreferencesStatus.loading));
    try {
      final preference = await _repository.getPreferences();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PreferencesStatus.success,
          currentPreference: preference,
          interests: List.of(preference.interests),
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PreferencesStatus.error,
            errorMessage: ListingRepository.errorMessage(error),
          ),
        );
      }
    }
  }

  void toggleInterest(String code) {
    if (state.status == PreferencesStatus.updating) return;
    final selected = List<String>.of(state.interests);
    if (selected.contains(code)) {
      selected.remove(code);
    } else {
      if (selected.length >= 5) return;
      selected.add(code);
    }
    emit(
      state.copyWith(status: PreferencesStatus.success, interests: selected),
    );
  }

  Future<void> updatePreferences() async {
    if (state.status == PreferencesStatus.updating ||
        state.currentPreference == null) {
      return;
    }
    if (state.interests.length > 5) {
      emit(
        state.copyWith(
          status: PreferencesStatus.error,
          errorMessage: 'Bạn chỉ được chọn tối đa 5 sở thích.',
        ),
      );
      return;
    }
    final current = state.currentPreference!;
    final request = UserPreference(
      interests: List.of(state.interests),
      minBudget: current.minBudget,
      maxBudget: current.maxBudget,
      hasPet: current.hasPet,
      preferredArea: current.preferredArea,
    );
    emit(state.copyWith(status: PreferencesStatus.updating));
    try {
      final updated = await _repository.updatePreferences(request);
      if (updated.interests.length != request.interests.length ||
          !updated.interests.toSet().containsAll(request.interests)) {
        throw Exception(
          'Máy chủ chưa lưu đúng sở thích. Hãy khởi động lại backend và thử lại.',
        );
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PreferencesStatus.updateSuccess,
            currentPreference: updated,
            interests: List.of(updated.interests),
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PreferencesStatus.error,
            errorMessage: ListingRepository.errorMessage(error),
          ),
        );
      }
    }
  }
}
