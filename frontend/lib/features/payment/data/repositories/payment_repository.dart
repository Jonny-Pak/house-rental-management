import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/payment_transaction.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  Future<PaymentTransaction> getStatus(String reference) async {
    final response = await _apiClient.get(
      '/payments/${Uri.encodeComponent(reference)}/status',
    );
    return PaymentTransaction.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<PaymentTransaction>> getHistory() async {
    final response = await _apiClient.get('/payments/me');
    final items = <PaymentTransaction>[];
    for (final item in response.data as List) {
      items.add(PaymentTransaction.fromJson(Map<String, dynamic>.from(item)));
    }
    return items;
  }

  Future<bool> openPayment(Uri uri) async =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static String errorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return 'Vui lòng đăng nhập lại để xem giao dịch thanh toán.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Chưa kết nối được máy chủ. Vui lòng kiểm tra lại giao dịch sau.';
    }
    return error.toString();
  }

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
