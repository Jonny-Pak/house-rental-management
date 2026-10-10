import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_listing_model.dart';

class AdminListingRepository {
  final ApiClient _apiClient;

  AdminListingRepository(this._apiClient);

  Future<List<AdminListingModel>> getPendingListings() async {
    try {
      final response = await _apiClient.get('/admin/listings/pending');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => AdminListingModel.fromJson(e)).toList();
      }
      throw Exception('Failed to load pending listings');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<void> approveListing(int id) async {
    try {
      final response = await _apiClient.patch('/admin/listings/$id/approve');
      if (response.statusCode != 200) {
        throw Exception('Failed to approve listing');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<void> rejectListing(int id, String reason) async {
    try {
      final response = await _apiClient.patch(
        '/admin/listings/$id/reject',
        data: {'reason': reason},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reject listing');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}

