import 'package:equatable/equatable.dart';
import '../../../property/data/models/property_model.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<PropertyModel> properties;
  final String? errorMessage;
  final Map<String, dynamic>? filters;

  const HomeState({
    this.status = HomeStatus.initial,
    this.properties = const [],
    this.errorMessage,
    this.filters,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<PropertyModel>? properties,
    String? errorMessage,
    Map<String, dynamic>? filters,
  }) {
    return HomeState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [status, properties, errorMessage, filters];
}
