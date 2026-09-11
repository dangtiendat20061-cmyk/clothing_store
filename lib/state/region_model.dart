import 'package:flutter/foundation.dart';
 
/// Quản lý trạng thái VN / Quốc tế, dùng chung cho cả list sản phẩm và giỏ hàng.
class RegionModel extends ChangeNotifier {
  bool _isInternational = false;
 
  bool get isInternational => _isInternational;
 
  void toggle() {
    _isInternational = !_isInternational;
    notifyListeners();
  }
 
  void setFromCountryCode(String countryCode) {
    _isInternational = countryCode != 'VN';
    notifyListeners();
  }
 
  /// Tính giá hiển thị theo vùng hiện tại.
  double priceFor(int priceVnd) {
    return _isInternational ? (priceVnd * 4).toDouble() : priceVnd.toDouble();
  }
}