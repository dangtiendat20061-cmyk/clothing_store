import 'package:flutter/foundation.dart';
import '../service/auth_service.dart';
 
/// Quản lý trạng thái đăng nhập của người dùng trong toàn app.
class AuthModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
 
  String? _token;
  int? _userId;
  String? _fullName;
  String? _email;
  bool _isLoading = false;
 
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get fullName => _fullName;
  String? get email => _email;
 
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      _applyAuthResponse(data);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.login(email: email, password: password);
      _applyAuthResponse(data);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
  void _applyAuthResponse(Map<String, dynamic> data) {
    _token = data['token'];
    _userId = data['userId'];
    _fullName = data['fullName'];
    _email = data['email'];
  }
 
  void logout() {
    _token = null;
    _userId = null;
    _fullName = null;
    _email = null;
    notifyListeners();
  }
}
 