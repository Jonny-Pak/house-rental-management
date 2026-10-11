import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/listing_model.dart';

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
  final ApiClient _apiClient;

  HomeMapCubit(this._apiClient) : super(HomeMapInitial());

  Future<void> fetchApprovedListings() async {
    emit(HomeMapLoading());
    try {
      final response = await _apiClient.get('/listings/public');
      if (response.statusCode == 200) {
        final dynamic body = response.data;
        List<dynamic> listData = [];
        if (body is List) {
          listData = body;
        } else if (body is Map && body['data'] is List) {
          listData = body['data'];
        }

        final listings = listData
            .map((item) => Listing.fromJson(item as Map<String, dynamic>))
            .toList();

        emit(HomeMapLoaded(listings));
      } else {
        emit(HomeMapError('Không thể tải danh sách bài đăng'));
      }
    } catch (e) {
      emit(HomeMapError(e.toString()));
    }
  }
}

