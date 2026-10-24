import '../../../../core/network/api_client.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  Future<String> getVnPayUrl(int packageId) async {
    try {
      final response = await _apiClient.post(
        '/payments/create',
        {'packageId': packageId},
      );

      if (response.data != null && response.data['paymentUrl'] != null) {
        return response.data['paymentUrl'] as String;
      } else {
        throw Exception('Phản hồi không chứa paymentUrl');
      }
    } catch (e) {
      throw Exception('Không thể tạo liên kết thanh toán: $e');
    }
  }
}
