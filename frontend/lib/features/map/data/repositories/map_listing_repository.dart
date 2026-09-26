import '../../../../core/network/api_client.dart';
import '../models/map_listing_model.dart';

class MapListingRepository {
  final ApiClient _apiClient;

  MapListingRepository(this._apiClient);

  Future<List<MapListingModel>> fetchListingsInArea({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    final response = await _apiClient.get(
      '/listings/map',
      queryParams: {
        'minLat': minLat,
        'minLng': minLng,
        'maxLat': maxLat,
        'maxLng': maxLng,
      },
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => MapListingModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load map listings');
  }
}
