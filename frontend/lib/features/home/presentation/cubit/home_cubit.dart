import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../property/data/repositories/property_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final PropertyRepository _repository;

  HomeCubit(this._repository) : super(const HomeState()) {
    fetchProperties();
  }

  Future<void> fetchProperties({Map<String, dynamic>? filters, bool clearFilters = false}) async {
    emit(state.copyWith(
      status: HomeStatus.loading, 
      filters: filters, 
      clearFilters: clearFilters,
      errorMessage: null, // Clear error on retry
    ));
    try {
      final currentFilters = clearFilters ? null : (filters ?? state.filters);
      final properties = await _repository.fetchProperties(filters: currentFilters);
      emit(state.copyWith(
        status: HomeStatus.success,
        properties: properties,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
