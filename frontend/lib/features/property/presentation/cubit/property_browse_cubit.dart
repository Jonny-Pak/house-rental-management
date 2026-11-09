import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/property_model.dart';
import '../../data/repositories/property_repository.dart';

abstract class PropertyBrowseState {}

class PropertyBrowseInitial extends PropertyBrowseState {}
class PropertyBrowseLoading extends PropertyBrowseState {}
class PropertyBrowseLoaded extends PropertyBrowseState {
  final List<PropertyModel> properties;
  PropertyBrowseLoaded(this.properties);
}
class PropertyBrowseError extends PropertyBrowseState {
  final String message;
  PropertyBrowseError(this.message);
}

class PropertyBrowseCubit extends Cubit<PropertyBrowseState> {
  final PropertyRepository _repository;

  PropertyBrowseCubit(this._repository) : super(PropertyBrowseInitial());

  Future<void> loadProperties(String propertyType) async {
    emit(PropertyBrowseLoading());
    try {
      final properties = await _repository.fetchProperties(filters: {'propertyType': propertyType});
      emit(PropertyBrowseLoaded(properties));
    } catch (e) {
      emit(PropertyBrowseError(e.toString()));
    }
  }
}
