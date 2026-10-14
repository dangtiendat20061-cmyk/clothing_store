import 'package:flutter/foundation.dart';
import '../utils/format.dart';

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

  double priceFor(int priceVnd) {
    return _isInternational ? (priceVnd * 4).toDouble() : priceVnd.toDouble();
  }

  String formatPrice(int priceVnd) {
    final value = priceFor(priceVnd);
    return _isInternational ? formatUsd(value) : formatVnd(value);
  }
}