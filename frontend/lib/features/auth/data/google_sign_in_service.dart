import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  const GoogleSignInService({this.webClientId = defaultWebClientId});

  static const defaultWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '163320326790-qpth0te5vfpp3b386lrmbdh1mucqhle8.apps.googleusercontent.com',
  );
  final String webClientId;
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static Future<void>? _initialization;

  Future<String?> getIdToken() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const GoogleLoginException(
        'Hãy dùng Google trên app Android hoặc iOS. Trên thiết bị này, bạn có thể đăng nhập bằng email.',
      );
    }
    if (webClientId.isEmpty || webClientId.contains('example')) {
      throw const GoogleLoginException(
        'Đăng nhập Google chưa được cấu hình. Cần thêm GOOGLE_WEB_CLIENT_ID khi chạy app.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isEmpty) {
      throw const GoogleLoginException(
        'Cần cấu hình GOOGLE_IOS_CLIENT_ID và URL scheme Google cho app iOS.',
      );
    }
    final google = GoogleSignIn.instance;
    try {
      _initialization ??= google.initialize(
        serverClientId: webClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? iosClientId
            : null,
      );
      await _initialization;
    } catch (_) {
      _initialization = null;
      throw const GoogleLoginException(
        'Chưa khởi tạo được Google. Vui lòng kiểm tra cấu hình Client ID của ứng dụng.',
      );
    }
    try {
      await google.signOut();
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const GoogleLoginException(
          'Google chưa cấp ID token. Vui lòng kiểm tra Web Client ID.',
        );
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const GoogleLoginException(
          'Cấu hình Google chưa đúng. Kiểm tra Client ID, tên package và SHA-1 của app.',
        );
      }
      throw const GoogleLoginException(
        'Chưa đăng nhập được Google. Kiểm tra kết nối mạng và thử lại.',
      );
    }
  }
}

class GoogleLoginException implements Exception {
  const GoogleLoginException(this.message);
  final String message;

  @override
  String toString() => message;
}
