import '../../../listing/data/models/listing_filter.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../listing/data/repositories/listing_repository.dart';
import '../../../listing/data/models/listing_model.dart';

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

class HomeMapCubit extends Cubit<HomeMapState> {
  final ListingRepository _repository;

  HomeMapCubit(this._repository) : super(HomeMapInitial());
  ListingFilter filter = const ListingFilter();
  int _request = 0;

  Future<void> fetchApprovedListings({bool silent = false}) async {
    if (isClosed) return;
    final request = ++_request;
    final search = filter;
    if (!silent) emit(HomeMapLoading());
    try {
      final listings = search.hasRadius
          ? await _repository.fetchNearby(
              search.center!.latitude,
              search.center!.longitude,
              search.radiusKm!,
            )
          : await _repository.fetchApprovedListings();
      if (!isClosed && request == _request) emit(HomeMapLoaded(listings));
    } catch (e) {
      if (!isClosed &&
          request == _request &&
          !(silent && state is HomeMapLoaded)) {
        emit(HomeMapError(ListingRepository.errorMessage(e)));
      }
    }
  }
}
