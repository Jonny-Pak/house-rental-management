import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            // Use localhost for Windows desktop/Web testing.
            // Change to 'http://10.0.2.2:8080/api/v1' for Android emulator.
            baseUrl: 'http://localhost:8080/api/v1',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<Response> post(String path, Map<String, dynamic> data) async {
    return _dio.post(path, data: data);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _dio.get(path, queryParameters: queryParams);
  }
}
