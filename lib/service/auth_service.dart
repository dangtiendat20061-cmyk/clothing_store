import 'dart:convert';
import 'package:http/http.dart' as http;
 
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:9823/api';
}
 
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
 
class AuthService {
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );
 
    final data = json.decode(response.body);
 
    if (response.statusCode == 200) {
      return data;
    } else {
      throw ApiException(data['message'] ?? 'Đăng ký thất bại.');
    }
  }
 
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
 
    final data = json.decode(response.body);
 
    if (response.statusCode == 200) {
      return data;
    } else {
      throw ApiException(data['message'] ?? 'Đăng nhập thất bại.');
    }
  }
}