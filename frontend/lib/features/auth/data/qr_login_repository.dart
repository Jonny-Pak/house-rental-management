import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'models/auth_models.dart';

class QrLoginSession {
  const QrLoginSession({
    required this.id,
    required this.browserSecret,
    required this.qrData,
    required this.verificationCode,
    required this.expiresAt,
  });
  final String id, browserSecret, qrData, verificationCode;
  final DateTime expiresAt;

  factory QrLoginSession.fromJson(Map<String, dynamic> json) => QrLoginSession(
    id: json['id'] as String,
    browserSecret: json['browserSecret'] as String,
    qrData: json['qrData'] as String,
    verificationCode: json['verificationCode'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

class QrLoginCode {
  const QrLoginCode(this.id, this.scanToken);
  final String id, scanToken;

  static QrLoginCode parse(String text) {
    if (text.length > 512) throw const FormatException('Nội dung QR quá dài.');
    final uri = Uri.tryParse(text.trim());
    if (uri == null ||
        uri.scheme != 'houserental' ||
        uri.host != 'admin-login' ||
        uri.pathSegments.length != 1) {
      throw const FormatException('Đây không phải mã đăng nhập Rental Admin.');
    }
    final id = uri.pathSegments.first;
    final tokens = uri.queryParametersAll['token'];
    if (!RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
        ).hasMatch(id) ||
        tokens == null ||
        tokens.length != 1 ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(tokens.first)) {
      throw const FormatException('Mã QR đăng nhập không hợp lệ.');
    }
    return QrLoginCode(id, tokens.first);
  }
}

class QrLoginPreview {
  const QrLoginPreview({
    required this.website,
    required this.browserName,
    required this.verificationCode,
    required this.expiresAt,
  });
  final String website, browserName, verificationCode;
  final DateTime expiresAt;

  factory QrLoginPreview.fromJson(Map<String, dynamic> json) => QrLoginPreview(
    website: json['website'] as String,
    browserName: json['browserName'] as String,
    verificationCode: json['verificationCode'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

class QrLoginRepository {
  QrLoginRepository(this.client);
  final ApiClient client;

  Future<QrLoginSession> start() async {
    final response = await client.post('/auth/qr/start', {});
    return QrLoginSession.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<String> status(QrLoginSession session) async {
    final response = await client.post('/auth/qr/${session.id}/status', {
      'browserSecret': session.browserSecret,
    });
    return response.data['status'] as String;
  }

  Future<void> cancel(QrLoginSession session) async {
    await client.post('/auth/qr/${session.id}/cancel', {
      'browserSecret': session.browserSecret,
    });
  }

  Future<AuthResponse> consume(QrLoginSession session) async {
    final response = await client.post('/auth/qr/${session.id}/consume', {
      'browserSecret': session.browserSecret,
    });
    return AuthResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<QrLoginPreview> preview(QrLoginCode code) async {
    final response = await client.post('/admin/qr-login/${code.id}/preview', {
      'scanToken': code.scanToken,
    });
    return QrLoginPreview.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> decide(QrLoginCode code, bool approve) async {
    await client.post('/admin/qr-login/${code.id}/decision', {
      'scanToken': code.scanToken,
      'approve': approve,
    });
  }

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Không kết nối được máy chủ. Vui lòng thử lại.';
    }
    if (error is FormatException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
