import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8080/api/v1',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Response> post(String path, dynamic data) async {
    return _dio.post(path, data: data);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> put(String path, Map<String, dynamic> data) async {
    return _dio.put(path, data: data);
  }
}
