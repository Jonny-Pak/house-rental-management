import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Base URL trỏ tới Backend trên Render (hoặc ghi đè bằng --dart-define=API_BASE_URL=...)
String get _baseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) return configuredUrl;
  return 'https://house-rental-backend-b03i.onrender.com/api/v1';
}

class ApiClient {
  final Dio _dio;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          // Render Free may take a few minutes to wake a sleeping backend.
          connectTimeout: const Duration(seconds: 240),
          receiveTimeout: const Duration(seconds: 240),
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

  Future<Response> post(String path, dynamic data, {Options? options}) async {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> getBytes(String path) =>
      _dio.get(path, options: Options(responseType: ResponseType.bytes));

  Future<Response> put(String path, Map<String, dynamic> data) async {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async => _dio.delete(path);
}
