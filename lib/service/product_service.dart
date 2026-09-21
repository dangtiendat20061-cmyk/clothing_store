import 'dart:convert';
import 'package:http/http.dart' as http;
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
}
