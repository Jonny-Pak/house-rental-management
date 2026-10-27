import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  Future<String> getVnPayUrl(int packageId) async {
    try {
      final response = await _apiClient.post('/payments/create', {
        'packageId': packageId,
      });

      if (response.data != null && response.data['paymentUrl'] != null) {
        return response.data['paymentUrl'] as String;
      } else {
        throw Exception('Phản hồi không chứa paymentUrl');
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        throw Exception(data['message']);
      }
      throw Exception(
        'Không kết nối được máy chủ thanh toán. Vui lòng thử lại.',
      );
    }
  }
}
