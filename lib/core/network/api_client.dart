import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_endpoints.dart';

const _tokenKey = 'jwt_token';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// 未登录事件流（401 时触发），路由层监听后跳转
final unauthenticatedEventProvider = StreamProvider<void>((ref) {
  return ref.watch(apiClientProvider).unauthenticatedStream;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  // 401 事件广播流，路由层监听
  final _unauthController = StreamController<void>.broadcast();
  Stream<void> get unauthenticatedStream => _unauthController.stream;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // 拦截器：自动携带 JWT token，401 时清除 token 并广播未登录事件
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // 记录本次请求是否携带了 token，避免未登录请求的 401 误清理刚写入的 token
          options.extra['hadAuthToken'] = token != null;
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final hadAuthToken =
                error.requestOptions.extra['hadAuthToken'] == true;
            if (hadAuthToken) {
              await _secureStorage.delete(key: _tokenKey);
              _unauthController.add(null);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ── Token 管理 ──────────────────────────────────────────────
  Future<void> saveToken(String token) =>
      _secureStorage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _secureStorage.delete(key: _tokenKey);

  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

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

  /// 同 _unwrap，但允许 data 字段为 null（如 GET /api/pets 无西瓜时）
  Map<String, dynamic>? _unwrapNullable(Response resp) {
    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(data['message'] as String? ?? '请求失败');
    }
    final inner = data['data'];
    if (inner == null) return null;
    return inner as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getNullable(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = await _dio.get(path, queryParameters: queryParameters);
    return _unwrapNullable(resp);
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
