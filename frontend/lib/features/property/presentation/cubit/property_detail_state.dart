import 'package:equatable/equatable.dart';
import '../../data/models/property_model.dart';
import '../../data/models/room_model.dart';

enum PropertyDetailStatus { initial, loading, success, error }

class PropertyDetailState extends Equatable {
  final PropertyDetailStatus status;
  final PropertyModel? property;
  final List<RoomModel> rooms;
  final String? errorMessage;

  const PropertyDetailState({
    this.status = PropertyDetailStatus.initial,
    this.property,
    this.rooms = const [],
    this.errorMessage,
  });

  PropertyDetailState copyWith({
    PropertyDetailStatus? status,
    PropertyModel? property,
    List<RoomModel>? rooms,
    String? errorMessage,
  }) {
    return PropertyDetailState(
      status: status ?? this.status,
      property: property ?? this.property,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, property, rooms, errorMessage];
}
