import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_listing_model.dart';

class AdminListingRepository {
  final ApiClient _apiClient;

  AdminListingRepository(this._apiClient);

  String _extractError(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return fallback;
  }

  Future<List<AdminListingModel>> getPendingListings() async {
    try {
      final response = await _apiClient.get('/admin/listings/pending');
      if (response.statusCode == 200) {
        final dynamic raw = response.data;
        List<dynamic> list = [];
        if (raw is Map && raw['data'] is List) {
          list = raw['data'];
        } else if (raw is List) {
          list = raw;
        }
        return list.map((e) => AdminListingModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Không thể tải danh sách bài đăng');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Chưa đăng nhập hoặc không có quyền Admin. Vui lòng đăng nhập!');
      }
      throw Exception(_extractError(e.response?.data, e.message ?? 'Lỗi kết nối máy chủ'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> approveListing(int id) async {
    try {
      final response = await _apiClient.patch('/admin/listings/$id/approve');
      if (response.statusCode != 200) {
        throw Exception('Phê duyệt bài đăng thất bại');
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.message ?? 'Lỗi khi phê duyệt'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> rejectListing(int id, String reason) async {
    try {
      final response = await _apiClient.patch(
        '/admin/listings/$id/reject',
        data: {'reason': reason},
      );
      if (response.statusCode != 200) {
        throw Exception('Từ chối bài đăng thất bại');
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e.response?.data, e.message ?? 'Lỗi khi từ chối'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
