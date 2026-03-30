import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/circle_model.dart';

final circleRepositoryProvider = Provider<CircleRepository>(
  (ref) => CircleRepository(ref.watch(apiClientProvider)),
);

class CircleRepository {
  final ApiClient _client;
  CircleRepository(this._client);

  Future<CircleModel?> fetchCircle(String circleId) => _fetchCircle(circleId);

  Future<CircleModel?> _fetchCircle(String circleId) async {
    try {
      final data = await _client.get(ApiEndpoints.circleById(circleId));
      return CircleModel.fromJson(data);
    } on ApiException {
      return null;
    }
  }

  Future<void> createCircle({required String name}) async {
    await _client.post(ApiEndpoints.circles, body: {'name': name});
  }

  /// 返回 true 表示加入成功
  Future<bool> joinCircleByCode(String inviteCode) async {
    try {
      await _client.post(ApiEndpoints.joinCircle, body: {
        'inviteCode': inviteCode.toUpperCase(),
      });
      return true;
    } on ApiException {
      return false;
    }
  }
}
