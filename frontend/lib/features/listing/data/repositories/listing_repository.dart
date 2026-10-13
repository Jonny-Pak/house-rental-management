import '../../../../core/network/api_client.dart';
import '../models/listing_model.dart';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ListingRepository {
  ListingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Listing> fetchDetail(int id) async {
    final response = await _apiClient.get('/listings/public/$id');
    return Listing.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<bool> isFavorite(int id) async {
    final response = await _apiClient.get('/listings/$id/favorite');
    return response.data['isFavorite'] == true;
  }

  Future<void> setFavorite(int id, bool saved) async {
    if (saved) {
      await _apiClient.put('/listings/$id/favorite', {});
    } else {
      await _apiClient.delete('/listings/$id/favorite');
    }
  }

  Future<List<Listing>> fetchSavedListings() async {
    final response = await _apiClient.get('/listings/favorites/me');
    return (response.data as List)
        .map((item) => Listing.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Listing>> fetchMyListings() async {
    final response = await _apiClient.get('/listings/me');
    return (response.data as List)
        .map((item) => Listing.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<String> uploadImage(String path) async {
    final file = XFile(path);
    final response = await _apiClient.post(
      '/images/upload',
      FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
        ),
      }),
    );
    return response.data['data'] as String;
  }

  Future<Listing> createListing(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/listings', data);
    return Listing.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> updateListing(int id, Map<String, dynamic> data) async {
    await _apiClient.put('/listings/$id', data);
  }

  Future<void> updateRentalStatus(int id, String status) async {
    await _apiClient.patch(
      '/listings/$id/rental-status',
      data: {'rentalStatus': status},
    );
  }

  Future<void> deleteListing(int id) async {
    await _apiClient.delete('/listings/$id');
  }

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        if (data['data'] is Map) return (data['data'] as Map).values.join('\n');
        return data['message'] as String;
      }
      return 'Không thể kết nối máy chủ. Vui lòng thử lại.';
    }
    return error.toString();
  }

  Future<List<Listing>> fetchApprovedListings() async {
    final response = await _apiClient.get('/listings/public');
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách bài đăng');
    }

    final dynamic body = response.data;
    final List<dynamic> data;
    if (body is List) {
      data = body;
    } else if (body is Map && body['data'] is List) {
      data = body['data'];
    } else {
      data = [];
    }
    return data
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
