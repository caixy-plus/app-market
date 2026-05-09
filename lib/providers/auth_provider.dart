import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userName;
  String? _token;
  String? _refreshToken;
  int? _userId;
  String? _email;
  final ApiClient _apiClient = ApiClient();

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get token => _token;
  int? get userId => _userId;
  String? get email => _email;

  AuthProvider() {
    _apiClient.onUnauthorized = () {
      logout();
    };
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('accessToken');
      _refreshToken = prefs.getString('refreshToken');
      _userName = prefs.getString('user_name');
      _email = prefs.getString('user_email');
      final idStr = prefs.getString('user_id');
      _userId = idStr != null ? int.tryParse(idStr) : null;
    } catch (_) {
      _token = null;
      _refreshToken = null;
      _userName = null;
      _email = null;
      _userId = null;
    }
    _isLoggedIn = _token != null && _token!.isNotEmpty;
    if (_isLoggedIn) {
      _fetchUser();
    }
    notifyListeners();
  }

  Future<void> _fetchUser() async {
    try {
      final data = await _apiClient.getMe();
      _userId = data['id'] as int?;
      _email = data['email'] as String?;
      _userName = data['email'] as String?; // 用 email 作为显示名
      final prefs = await SharedPreferences.getInstance();
      if (_email != null) prefs.setString('user_email', _email!);
      if (_userId != null) prefs.setString('user_id', _userId.toString());
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    try {
      final data = await _apiClient.login(email, password);
      _token = data['accessToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      _email = email;
      _userName = email;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      if (_token != null) prefs.setString('accessToken', _token!);
      if (_refreshToken != null) prefs.setString('refreshToken', _refreshToken!);
      prefs.setString('user_name', email);
      prefs.setString('user_email', email);

      notifyListeners();
      _fetchUser();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register(String email, String password, {String? code}) async {
    try {
      final data = await _apiClient.register(email, password, code: code);
      _token = data['accessToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      _email = email;
      _userName = email;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      if (_token != null) prefs.setString('accessToken', _token!);
      if (_refreshToken != null) prefs.setString('refreshToken', _refreshToken!);
      prefs.setString('user_name', email);
      prefs.setString('user_email', email);

      notifyListeners();
      _fetchUser();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await _apiClient.logoutApi();
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
    _token = null;
    _refreshToken = null;
    _userName = null;
    _email = null;
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // 兼容旧接口
  void loginWithToken(String name, String token) {
    _token = token;
    _userName = name;
    _isLoggedIn = true;
    notifyListeners();
  }
}
