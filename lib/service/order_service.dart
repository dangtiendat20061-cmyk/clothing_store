import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/product.dart';
import 'auth_service.dart'; // để dùng chung ApiConfig, ApiException

/// 1 sản phẩm trong 1 đơn hàng đã đặt (dữ liệu trả về từ API, không phải Product gốc)
class OrderItemResult {
  final int productId;
  final String productName;
  final int quantity;
  final int priceAtPurchase;
  final String? size;

  OrderItemResult({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtPurchase,
    required this.size,
  });

  factory OrderItemResult.fromJson(Map<String, dynamic> json) {
    return OrderItemResult(
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      priceAtPurchase: json['priceAtPurchase'],
      size: json['size']?.toString(),
    );
  }
}

class OrderResult {
  final int id;
  final double totalPrice;
  final String status;
  final String? shippingAddress;
  final String? cancellationReason;
  final String? customerName;
  final String? phone;
  final DateTime createdAt;
  final List<OrderItemResult> items;

  OrderResult({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.shippingAddress,
    required this.cancellationReason,
    required this.customerName,
    required this.phone,
    required this.createdAt,
    required this.items,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      id: json['id'],
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'],
      shippingAddress: json['shippingAddress'],
      cancellationReason: json['cancellationReason']?.toString(),
      customerName: json['customerName']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List)
          .map((i) => OrderItemResult.fromJson(i))
          .toList(),
    );
  }
}

class OrderService {
  Future<Map<String, dynamic>> createOrder({
    required String token,
    required Map<Product, int> cartQuantities,
    required String shippingAddress,
    required String phone,
    required Map<int, String> itemSizes,
    required bool isInternational,
  }) async {
    final items = cartQuantities.entries.map((e) {
      return {
        'productId': e.key.id,
        'quantity': e.value,
        if (itemSizes[e.key.id]?.isNotEmpty == true)
          'size': itemSizes[e.key.id],
      };
    }).toList();

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'items': items,
          'shippingAddress': shippingAddress,
          'phone': phone,
          'isInternational': isInternational,
        }),
      ).timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException(
        'Không kết nối được backend qua HTTPS. Hãy chạy ClothingStoreApi bằng profile HTTPS và kiểm tra chứng chỉ localhost.',
      );
    } on TimeoutException {
      throw ApiException('Backend không phản hồi sau 20 giây. Kiểm tra API và MySQL rồi thử lại.');
    } on FormatException {
      throw ApiException(
        'Backend trả về dữ liệu không hợp lệ. Kiểm tra log C# để biết chi tiết.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.trim().isEmpty) return const <String, dynamic>{};
      final data = json.decode(response.body);
      return data is Map<String, dynamic> ? data : const <String, dynamic>{};
    }

    String message = 'Đặt hàng thất bại.';
    if (response.body.trim().isNotEmpty) {
      try {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          message = data['message']?.toString() ??
              data['detail']?.toString() ??
              _validationMessage(data['errors']) ??
              data['title']?.toString() ?? message;
        }
      } catch (_) {
        // Giữ thông báo mặc định nếu backend không trả JSON.
      }
    }
    if (message == 'Đặt hàng thất bại.' && response.statusCode == 401) {
      message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    } else if (message == 'Đặt hàng thất bại.' && response.statusCode >= 500) {
      message = 'Máy chủ đang gặp sự cố (${response.statusCode}). Vui lòng thử lại sau.';
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  String? _validationMessage(dynamic errors) {
    if (errors is! Map) return null;
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Lấy danh sách đơn hàng của người dùng đang đăng nhập
  Future<List<OrderResult>> fetchMyOrders(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/my'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => OrderResult.fromJson(json)).toList();
    } else {
      throw ApiException(
        response.statusCode == 401
            ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
            : 'Không tải được lịch sử đơn hàng.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<OrderResult>> fetchAllOrders(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((item) => OrderResult.fromJson(item)).toList();
    }
    throw _responseException(response, 'Không tải được danh sách đơn hàng.');
  }

  Future<void> updateOrderStatus({
    required String token,
    required int orderId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseException(response, 'Không cập nhật được trạng thái đơn hàng.');
    }
  }

  Future<void> cancelOrder({
    required String token,
    required int orderId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'reason': reason}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseException(response, 'Không hủy được đơn hàng.');
    }
  }

  Future<void> deleteCancelledHistory({
    required String token,
    required int orderId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/history'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseException(response, 'Không xóa được lịch sử đơn hàng.');
    }
  }

  ApiException _responseException(http.Response response, String fallback) {
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
