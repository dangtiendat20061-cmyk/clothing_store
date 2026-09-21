import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/product.dart';
import 'auth_service.dart'; // để dùng chung ApiConfig, ApiException
 
class OrderService {
  Future<Map<String, dynamic>> createOrder({
    required String token,
    required Map<Product, int> cartQuantities, // product -> quantity
    required String shippingAddress,
    required bool isInternational,
  }) async {
    final items = cartQuantities.entries.map((e) {
      return {
        'productId': e.key.id,
        'quantity': e.value,
      };
    }).toList();
 
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'items': items,
        'shippingAddress': shippingAddress,
        'isInternational': isInternational,
      }),
    );
 
    final data = json.decode(response.body);
 
    if (response.statusCode == 200) {
      return data;
    } else {
      throw ApiException(data['message'] ?? 'Đặt hàng thất bại.');
    }
  }
}