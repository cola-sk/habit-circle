import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_endpoints.dart';

const _tokenKey = 'jwt_token';

final _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // 拦截器：自动携带 JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // 401 时清除本地 token（已在 auth provider 处理登出逻辑）
          handler.next(error);
        },
      ),
    );
  }

  // ── Token 管理 ──────────────────────────────────────────────
  Future<void> saveToken(String token) =>
      _secureStorage.write(key: _tokenKey, value: token);

  Future<void> clearToken() =>
      _secureStorage.delete(key: _tokenKey);

  Future<String?> getToken() =>
      _secureStorage.read(key: _tokenKey);

  // ── HTTP 便捷方法 ────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = await _dio.get(path, queryParameters: queryParameters);
    return _unwrap(resp);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final resp = await _dio.post(path, data: body);
    return _unwrap(resp);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final resp = await _dio.patch(path, data: body);
    return _unwrap(resp);
  }

  Map<String, dynamic> _unwrap(Response resp) {
    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(data['message'] as String? ?? '请求失败');
    }
    return data['data'] as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
