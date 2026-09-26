import 'package:equatable/equatable.dart';
import '../../data/models/map_listing_model.dart';

enum MapStatus { initial, loading, success, error }

class MapState extends Equatable {
  final MapStatus status;
  final List<MapListingModel> listings;
  final String? errorMessage;

  const MapState({
    this.status = MapStatus.initial,
    this.listings = const [],
    this.errorMessage,
  });

  MapState copyWith({
    MapStatus? status,
    List<MapListingModel>? listings,
    String? errorMessage,
  }) {
    return MapState(
      status: status ?? this.status,
      listings: listings ?? this.listings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, listings, errorMessage];
}
