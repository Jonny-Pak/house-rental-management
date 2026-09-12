import 'package:equatable/equatable.dart';
import '../../../property/data/models/property_model.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<PropertyModel> properties;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.properties = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<PropertyModel>? properties,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, properties, errorMessage];
}
