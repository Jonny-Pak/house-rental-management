import '../../../../core/network/api_client.dart';
import '../../../property/data/models/property_model.dart';

class FavoriteRepository {
  final ApiClient _apiClient;

  FavoriteRepository(this._apiClient);

  /// Toggle favorite for a property.
  /// Returns true if now favorited, false if un-favorited.
  Future<bool> toggleFavorite(int propertyId) async {
    final response = await _apiClient.post('/favorites/$propertyId', {});
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data']['isFavorite'] as bool;
    }
    throw Exception('Failed to toggle favorite');
  }

  /// Get all favorited properties for the current user.
  Future<List<PropertyModel>> getFavoriteProperties() async {
    final response = await _apiClient.get('/favorites/me');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load favorite properties');
  }
}
