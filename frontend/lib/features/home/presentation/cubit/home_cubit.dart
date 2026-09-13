import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../property/data/repositories/property_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final PropertyRepository _repository;

  HomeCubit(this._repository) : super(const HomeState()) {
    fetchProperties();
  }

  Future<void> fetchProperties([Map<String, dynamic>? filters]) async {
    emit(state.copyWith(status: HomeStatus.loading, filters: filters));
    try {
      final properties = await _repository.fetchProperties(filters: filters);
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
