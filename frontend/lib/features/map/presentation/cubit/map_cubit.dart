import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/map_listing_repository.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final MapListingRepository _repository;

  /// Debounce timer – prevents a flood of API calls while the user is
  /// still panning / zooming the map.
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 600);

  MapCubit(this._repository) : super(const MapState());

  /// Called whenever the visible map bounds change.
  /// Uses a debounce so we only hit the API after the user has stopped
  /// moving for [_debounceDuration].
  void fetchListingsInArea(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      if (isClosed) return;
      emit(state.copyWith(status: MapStatus.loading));
      try {
        final listings = await _repository.fetchListingsInArea(
          minLat: minLat,
          minLng: minLng,
          maxLat: maxLat,
          maxLng: maxLng,
        );
        if (!isClosed) {
          emit(state.copyWith(status: MapStatus.success, listings: listings));
        }
      } catch (e) {
        if (!isClosed) {
          emit(state.copyWith(
            status: MapStatus.error,
            errorMessage: e.toString(),
          ));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
