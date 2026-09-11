import 'package:flutter/foundation.dart';
import '../model/product.dart';
 
/// 1 dòng trong giỏ hàng: sản phẩm + số lượng.
class CartLine {
  final Product product;
  int quantity;
 
  CartLine({required this.product, this.quantity = 1});
}
 
/// Quản lý toàn bộ giỏ hàng: thêm, bớt, xóa, tính tổng.
class CartModel extends ChangeNotifier {
  final Map<String, CartLine> _lines = {}; // key = product.name
 
  List<CartLine> get lines => _lines.values.toList();
 
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);
 
  bool get isEmpty => _lines.isEmpty;
 
  void addProduct(Product product) {
    if (_lines.containsKey(product.name)) {
      _lines[product.name]!.quantity++;
    } else {
      _lines[product.name] = CartLine(product: product);
    }
    notifyListeners();
  }
 
  void decreaseProduct(Product product) {
    final line = _lines[product.name];
    if (line == null) return;
    if (line.quantity > 1) {
      line.quantity--;
    } else {
      _lines.remove(product.name);
    }
    notifyListeners();
  }
 
  void removeProduct(Product product) {
    _lines.remove(product.name);
    notifyListeners();
  }
 
  void clear() {
    _lines.clear();
    notifyListeners();
  }
 
  /// Tổng tiền, cần truyền vào hàm tính giá theo vùng (VN/quốc tế) từ RegionModel.
  double totalPrice(double Function(int priceVnd) priceFor) {
    return _lines.values.fold(0.0, (sum, line) {
      return sum + priceFor(line.product.priceVnd) * line.quantity;
    });
  }
}