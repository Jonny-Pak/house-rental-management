import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

/// Dynamically resolve baseUrl depending on platform:
/// - Android Emulator requires `10.0.2.2` to access host machine's localhost (8080).
/// - Web & iOS Simulator use `localhost`.
String get _baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080/api/v1';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    // 10.0.2.2 only works for Android Emulator. 
    // Using your current Wi-Fi IP (192.168.100.72) for physical device (Mi Note 10 Lite)
    return 'http://192.168.100.72:8080/api/v1';
  }
  return 'http://localhost:8080/api/v1';
}

class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
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

  Future<Response> patch(String path, {dynamic data}) async {
    return _dio.patch(path, data: data);
  }
}
