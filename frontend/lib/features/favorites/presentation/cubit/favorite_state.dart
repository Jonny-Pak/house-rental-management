import 'package:equatable/equatable.dart';
import '../../../property/data/models/property_model.dart';

enum FavoriteStatus { initial, loading, success, error }

class FavoriteState extends Equatable {
  final FavoriteStatus status;
  final List<PropertyModel> properties;
  final String? errorMessage;

  const FavoriteState({
    this.status = FavoriteStatus.initial,
    this.properties = const [],
    this.errorMessage,
  });

  FavoriteState copyWith({
    FavoriteStatus? status,
    List<PropertyModel>? properties,
    String? errorMessage,
  }) {
    return FavoriteState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, properties, errorMessage];
}
