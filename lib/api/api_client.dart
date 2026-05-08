import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/app_store_app.dart';
import 'mock_data.dart';

class ApiClient {
  static bool forceMock = false;
  late final Dio _dio;
  VoidCallback? onUnauthorized;

  ApiClient() {
    final baseUrl = AppConfig.baseUrl;

    _dio = Dio(BaseOptions(
      baseUrl: '$baseUrl/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // 本地 K8s 自签名证书忽略
    if (baseUrl.contains('local.caixy.xin')) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshToken = await _getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final res = await _dio.post('/v1/user/auth/refresh', data: {
                'refreshToken': refreshToken,
              });
              final data = _parseResponse(res, (d) => d as Map<String, dynamic>);
              final newAccess = data['accessToken'] as String?;
              final newRefresh = data['refreshToken'] as String?;
              if (newAccess != null && newAccess.isNotEmpty) {
                await _setToken(newAccess);
                if (newRefresh != null && newRefresh.isNotEmpty) {
                  await _setRefreshToken(newRefresh);
                }
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              // refresh 失败，继续走清除逻辑
            }
          }
          await _clearAllTokens();
          onUnauthorized?.call();
          return handler.next(error);
        }
        return handler.next(error);
      },
    ));
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('accessToken');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refreshToken');
    } catch (_) {
      return null;
    }
  }

  Future<void> _setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
    } catch (_) {}
  }

  Future<void> _setRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refreshToken', token);
    } catch (_) {}
  }

  Future<void> _clearAllTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
    } catch (_) {}
  }

  Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
    } catch (_) {}
  }

  T _parseResponse<T>(Response response, T Function(dynamic data) parser) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('code')) {
      final code = body['code'];
      if (code == 0 || code == '0') {
        return parser(body['data']);
      } else {
        throw ApiException(
          int.tryParse(code.toString()) ?? -1,
          body['message']?.toString() ?? '请求失败',
        );
      }
    }
    return parser(body);
  }

  // ========== 应用商店 API ==========

  String _currentPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return '';
  }

  Future<List<AppStoreApp>> browseApps({
    String? category,
    String? search,
    String sortBy = 'popular',
    int page = 1,
    int size = 20,
    String? platform,
  }) async {
    if (forceMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockData.browseApps(
        category: category,
        search: search,
        sortBy: sortBy,
        page: page,
        size: size,
      );
    }
    final p = platform ?? _currentPlatform();
    final response = await _dio.get('/v1/store/apps', queryParameters: {
      if (category != null && category != 'all') 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      'sortBy': sortBy,
      'page': page,
      'size': size,
      if (p.isNotEmpty) 'platform': p,
    });
    final data = _parseResponse(response, (d) => d);
    // PageResponse 格式: { records: [...], total, pageNum, pageSize }
    if (data is Map && data['records'] is List) {
      return (data['records'] as List)
          .map((e) => AppStoreApp.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // 兼容旧的数组格式
    if (data is List) {
      return data.map((e) => AppStoreApp.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <AppStoreApp>[];
  }

  Future<AppStoreApp> getAppDetail(String slug) async {
    if (forceMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      final app = MockData.getAppDetail(slug);
      if (app == null) throw ApiException(404, '应用不存在');
      return app;
    }
    final response = await _dio.get('/v1/store/apps/$slug');
    final data = _parseResponse(response, (d) => d);
    return AppStoreApp.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AppStoreApp>> getPopularApps({int limit = 10, String? platform}) async {
    if (forceMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockData.getPopularApps(limit: limit);
    }
    final p = platform ?? _currentPlatform();
    final response = await _dio.get('/v1/store/apps', queryParameters: {
      'sortBy': 'popular',
      'page': 1,
      'size': limit,
      if (p.isNotEmpty) 'platform': p,
    });
    final data = _parseResponse(response, (d) => d);
    if (data is Map && data['records'] is List) {
      return (data['records'] as List)
          .map((e) => AppStoreApp.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data.map((e) => AppStoreApp.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <AppStoreApp>[];
  }

  Future<List<AppStoreApp>> getLatestApps({int limit = 10, String? platform}) async {
    if (forceMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockData.getLatestApps(limit: limit);
    }
    final p = platform ?? _currentPlatform();
    final response = await _dio.get('/v1/store/apps', queryParameters: {
      'sortBy': 'newest',
      'page': 1,
      'size': limit,
      if (p.isNotEmpty) 'platform': p,
    });
    final data = _parseResponse(response, (d) => d);
    if (data is Map && data['records'] is List) {
      return (data['records'] as List)
          .map((e) => AppStoreApp.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data.map((e) => AppStoreApp.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <AppStoreApp>[];
  }

  Future<void> installApp(int appId, {int? uid, int? projectId}) async {
    await _dio.post('/v1/store/apps/$appId/install', queryParameters: {
      if (uid != null) 'uid': uid,
      if (projectId != null) 'projectId': projectId,
    });
  }

  Future<void> uninstallApp(int appId, {int? uid}) async {
    await _dio.delete('/v1/store/apps/$appId/install', queryParameters: {
      if (uid != null) 'uid': uid,
    });
  }

  Future<void> rateApp(int appId, {int? uid, required int rating, String? comment}) async {
    await _dio.post('/v1/store/apps/$appId/rate', data: {
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
  }

  Future<List<AppRating>> getAppRatings(int appId, {int page = 1, int size = 20}) async {
    if (forceMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockData.getAppRatings(appId);
    }
    final response = await _dio.get('/v1/store/apps/$appId/ratings', queryParameters: {
      'page': page,
      'size': size,
    });
    final data = _parseResponse(response, (d) => d);
    if (data is Map && data['records'] is List) {
      return (data['records'] as List)
          .map((e) => AppRating.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data.map((e) => AppRating.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <AppRating>[];
  }

  // ========== 用户授权 API ==========

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/v1/user/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parseResponse(response, (d) => d as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _dio.post('/v1/user/auth/register', data: {
      'email': email,
      'password': password,
    });
    return _parseResponse(response, (d) => d as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/v1/user/auth/me');
    return _parseResponse(response, (d) => d as Map<String, dynamic>);
  }

  Future<void> logoutApi() async {
    await _dio.post('/v1/user/auth/logout');
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/v1/user/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    return _parseResponse(response, (d) => d as Map<String, dynamic>);
  }

  // ========== 脑池 API ==========

  Future<List<Map<String, dynamic>>> getModels() async {
    final response = await _dio.get('/v1/brain/models');
    return _parseResponse(response, (d) {
      return (d as List).map((e) => e as Map<String, dynamic>).toList();
    });
  }

  Future<Map<String, dynamic>> chatCompletion({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final response = await _dio.post('/v1/brain/chat/completions', data: {
      'model': model,
      'messages': messages,
    });
    return _parseResponse(response, (d) => d as Map<String, dynamic>);
  }
}

class ApiException implements Exception {
  final int code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}
