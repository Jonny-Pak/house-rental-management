import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../listing/data/repositories/listing_repository.dart';
import '../../../listing/data/models/listing_model.dart';

// --- States ---
abstract class HomeMapState {}

class HomeMapInitial extends HomeMapState {}

class HomeMapLoading extends HomeMapState {}

class HomeMapLoaded extends HomeMapState {
  final List<Listing> listings;
  HomeMapLoaded(this.listings);
}

class HomeMapError extends HomeMapState {
  final String message;
  HomeMapError(this.message);
}

// --- Cubit ---
class HomeMapCubit extends Cubit<HomeMapState> {
  final ListingRepository _repository;

  HomeMapCubit(this._repository) : super(HomeMapInitial());
  bool _fetching = false;

  Future<void> fetchApprovedListings({bool silent = false}) async {
    if (_fetching || isClosed) return;
    _fetching = true;
    if (!silent) emit(HomeMapLoading());
    try {
      final listings = await _repository.fetchApprovedListings();
      if (!isClosed) emit(HomeMapLoaded(listings));
    } catch (e) {
      if (!isClosed && !(silent && state is HomeMapLoaded)) {
        emit(HomeMapError(ListingRepository.errorMessage(e)));
      }
    } finally {
      _fetching = false;
    }
  }
}
