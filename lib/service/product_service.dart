import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../model/product.dart';
import 'auth_service.dart'; // dùng chung ApiConfig, ApiException
 
class ProductService {
  Future<List<Product>> fetchAll() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products'),
    );
 
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw ApiException('Không tải được danh sách sản phẩm.');
    }
  }

  Future<Product> createProduct({
    required String token,
    required String name,
    required int priceVnd,
    String? imagePath,
    String? category,
    String? style,
    String? description,
    List<String> sizes = const [],
    List<String> images = const [],
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name.trim(),
        'priceVnd': priceVnd,
        'imagePath': imagePath?.trim().isEmpty == true ? null : imagePath?.trim(),
        'category': category?.trim().isEmpty == true ? null : category?.trim(),
        'style': style?.trim().isEmpty == true ? null : style?.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'sizes': sizes,
        'images': images,
      }),
    );

    dynamic data;
    try {
      data = response.body.trim().isEmpty ? null : json.decode(response.body);
    } on FormatException {
      throw ApiException('Backend trả về dữ liệu sản phẩm không hợp lệ.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data is Map<String, dynamic>) return Product.fromJson(data);
      throw ApiException('Backend không trả về sản phẩm vừa tạo.');
    }

    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException(message ?? 'Tài khoản chưa có quyền quản lý sản phẩm.');
    }
    throw ApiException(message ?? 'Không thêm được sản phẩm (${response.statusCode}).');
  }

  Future<Product> updateProduct({
    required String token,
    required int productId,
    required String name,
    required int priceVnd,
    String? imagePath,
    String? category,
    String? style,
    String? description,
    List<String> sizes = const [],
    List<String> images = const [],
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name.trim(),
        'priceVnd': priceVnd,
        'imagePath': imagePath?.trim().isEmpty == true ? null : imagePath?.trim(),
        'category': category?.trim().isEmpty == true ? null : category?.trim(),
        'style': style?.trim().isEmpty == true ? null : style?.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'sizes': sizes,
        'images': images,
      }),
    );

    dynamic data;
    try {
      data = response.body.trim().isEmpty ? null : json.decode(response.body);
    } on FormatException {
      throw ApiException('Backend trả về dữ liệu sản phẩm không hợp lệ.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic>) return Product.fromJson(data);
      throw ApiException('Backend không trả về sản phẩm vừa cập nhật.');
    }
    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException(message ?? 'Tài khoản chưa có quyền sửa sản phẩm.');
    }
    throw ApiException(message ?? 'Không sửa được sản phẩm (${response.statusCode}).');
  }

  Future<String> uploadImage({
    required String token,
    required PlatformFile file,
  }) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw ApiException('Không đọc được file ảnh đã chọn. Hãy chọn lại ảnh.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/products/upload-image'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    dynamic data;
    try {
      data = json.decode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300 &&
        data is Map<String, dynamic> && data['imageUrl'] is String) {
      return data['imageUrl'] as String;
    }
    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;
    throw ApiException(message ?? 'Tải ảnh lên thất bại (${response.statusCode}).');
  }

  Future<void> deleteProduct({
    required String token,
    required int productId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    dynamic data;
    try {
      data = json.decode(response.body);
    } catch (_) {
      data = null;
    }
    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException(message ?? 'Tài khoản chưa có quyền xóa sản phẩm.');
    }
    throw ApiException(message ?? 'Không xóa được sản phẩm (${response.statusCode}).');
  }
}
