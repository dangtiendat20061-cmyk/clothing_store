import 'package:flutter/foundation.dart';
import '../model/product.dart';
 
class CartLine {
  final Product product;
  int quantity;
 
  CartLine({required this.product, this.quantity = 1});
}
 
class CartModel extends ChangeNotifier {
  final Map<int, CartLine> _lines = {}; // key = product.id
 
  List<CartLine> get lines => _lines.values.toList();
 
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);
 
  bool get isEmpty => _lines.isEmpty;
 
  void addProduct(Product product, {int quantity = 1}) {
    if (_lines.containsKey(product.id)) {
      _lines[product.id]!.quantity += quantity;
    } else {
      _lines[product.id] = CartLine(product: product, quantity: quantity);
    }
    notifyListeners();
  }
 
  void decreaseProduct(Product product) {
    final line = _lines[product.id];
    if (line == null) return;
    if (line.quantity > 1) {
      line.quantity--;
    } else {
      _lines.remove(product.id);
    }
    notifyListeners();
  }
 
  void removeProduct(Product product) {
    _lines.remove(product.id);
    notifyListeners();
  }
 
  void clear() {
    _lines.clear();
    notifyListeners();
  }
 
  double totalPrice(double Function(int priceVnd) priceFor) {
    return _lines.values.fold(0.0, (sum, line) {
      return sum + priceFor(line.product.priceVnd) * line.quantity;
    });
  }
}