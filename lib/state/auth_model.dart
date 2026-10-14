import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/auth_service.dart';

class AuthModel extends ChangeNotifier {
  static const _kToken = 'auth_token';
  static const _kUserId = 'auth_user_id';
  static const _kFullName = 'auth_full_name';
  static const _kEmail = 'auth_email';
  static const _kRole = 'auth_role';

  final AuthService _authService = AuthService();

  String? _token;
  int? _userId;
  String? _fullName;
  String? _email;
  String? _role;
  bool _isLoading = false;
  bool _isRestoring = true;

  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  String? get token => _token;
  int? get userId => _userId;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get role => _role;
  bool get isAdmin => _role?.toLowerCase() == 'admin';

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_kToken);
      _userId = prefs.getInt(_kUserId);
      _fullName = prefs.getString(_kFullName);
      _email = prefs.getString(_kEmail);
      _role = prefs.getString(_kRole);
    } catch (_) {
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

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
      await _applyAuthResponse(data);
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
      await _applyAuthResponse(data);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> data) async {
    _token = data['token'];
    _userId = data['userId'];
    _fullName = data['fullName'];
    _email = data['email'];
    _role = data['role']?.toString();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, _token ?? '');
      await prefs.setInt(_kUserId, _userId ?? 0);
      await prefs.setString(_kFullName, _fullName ?? '');
      await prefs.setString(_kEmail, _email ?? '');
      await prefs.setString(_kRole, _role ?? '');
    } catch (_) {
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _fullName = null;
    _email = null;
    _role = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in [_kToken, _kUserId, _kFullName, _kEmail, _kRole]) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

 
