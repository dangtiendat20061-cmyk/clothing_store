import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

class ApiConfig {
  /// Web: gọi HTTPS (cần `dotnet dev-certs https --trust`).
  /// Android emulator: 10.0.2.2 là máy tính chủ (localhost là chính emulator).
  /// iOS simulator / desktop: localhost. Mobile dùng HTTP 5135 (backend đã
  /// tắt chuyển hướng HTTPS khi chạy Development). Đổi 1 chỗ này khi deploy.
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7251/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5135/api';
    }
    return 'http://localhost:5135/api';
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class AuthService {
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) {
    return _post('/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
    }, 'Đăng ký thất bại.');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post(
        '/auth/login', {'email': email, 'password': password}, 'Đăng nhập thất bại.');
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body, String fallback) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('Máy chủ không phản hồi. Kiểm tra backend và MySQL.');
    } on http.ClientException {
      throw ApiException(
          'Không kết nối được máy chủ. Hãy chạy backend (profile https) và bật MySQL.');
    }

    dynamic data;
    try {
      data = response.body.trim().isEmpty ? null : json.decode(response.body);
    } on FormatException {
      data = null;
    }

    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      return data;
    }
    final message = data is Map<String, dynamic> ? data['message']?.toString() : null;
    throw ApiException(message ?? '$fallback (${response.statusCode})',
        statusCode: response.statusCode);
  }
}

