import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

class AuthRepository {
  final ApiClient _client;
  AuthRepository(this._client);

  Future<void> sendCode(String phone) async {
    await _client.post(ApiEndpoints.sendCode, body: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyCode({
    required String phone,
    required String code,
  }) async {
    final data = await _client.post(
      ApiEndpoints.verifyCode,
      body: {'phone': phone, 'code': code},
    );
    final token = data['token'] as String;
    await _client.saveToken(token);
    return data;
  }

  Future<void> signOut() => _client.clearToken();

  Future<bool> isLoggedIn() async {
    final token = await _client.getToken();
    return token != null;
  }
}
