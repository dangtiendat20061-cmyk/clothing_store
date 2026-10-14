import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? phone;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as int,
        fullName: json['fullName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'Customer',
        isActive: json['isActive'] == true,
        phone: json['phone']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class AdminUserService {
  Future<List<AdminUser>> fetchUsers(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final rows = json.decode(response.body) as List<dynamic>;
      return rows
          .map((row) => AdminUser.fromJson(row as Map<String, dynamic>))
          .toList();
    }
    throw _error(response, 'Không tải được danh sách tài khoản.');
  }

  Future<void> setActive({
    required String token,
    required int userId,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/active'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'isActive': isActive}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _error(response, 'Không cập nhật được tài khoản.');
    }
  }

  ApiException _error(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        return ApiException(
          body['message']?.toString() ?? body['detail']?.toString() ?? fallback,
          statusCode: response.statusCode,
        );
      }
    } catch (_) {}
    return ApiException(fallback, statusCode: response.statusCode);
  }
}
