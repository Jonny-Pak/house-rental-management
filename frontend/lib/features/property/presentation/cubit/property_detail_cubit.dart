import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/property_repository.dart';
import 'property_detail_state.dart';

class PropertyDetailCubit extends Cubit<PropertyDetailState> {
  final PropertyRepository _repository;

  PropertyDetailCubit(this._repository) : super(const PropertyDetailState());

  Future<void> fetchPropertyDetails(int propertyId) async {
    emit(state.copyWith(status: PropertyDetailStatus.loading));
    try {
      final responses = await Future.wait([
        _repository.fetchPropertyDetails(propertyId),
        _repository.fetchRooms(propertyId),
      ]);

      emit(state.copyWith(
        status: PropertyDetailStatus.success,
        property: responses[0] as dynamic,
        rooms: responses[1] as dynamic,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PropertyDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
