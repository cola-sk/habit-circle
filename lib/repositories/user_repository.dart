import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(apiClientProvider)),
);

class UserRepository {
  final ApiClient _client;
  UserRepository(this._client);

  Stream<UserModel?> watchUser() => Stream.periodic(
        const Duration(seconds: 30),
        (_) => _fetchUser(),
      ).asyncMap((f) => f).asBroadcastStream();

  Future<UserModel?> _fetchUser() async {
    try {
      final data = await _client.get(ApiEndpoints.me);
      return UserModel.fromJson(data);
    } on ApiException {
      return null;
    }
  }

  Future<UserModel?> getUser() => _fetchUser();

  Future<void> createUser(UserModel user) async {
    await _client.patch(ApiEndpoints.me, body: {'childName': user.childName});
  }

  Future<void> updateChildName(String childName) async {
    await _client.patch(ApiEndpoints.me, body: {'childName': childName});
  }
}
