import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

final cheerRepositoryProvider = Provider<CheerRepository>(
  (ref) => CheerRepository(ref.watch(apiClientProvider)),
);

class CheerRepository {
  final ApiClient _client;
  CheerRepository(this._client);

  /// 给某人加油
  Future<void> sendCheer(String toUserId) async {
    await _client.post(ApiEndpoints.cheers, body: {'toUserId': toUserId});
  }

  /// 查询今天收到的加油人昵称列表
  Future<List<String>> fetchTodayCheers() async {
    try {
      final today = DateTime.now();
      final date =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final data = await _client.get('${ApiEndpoints.cheers}?date=$date');
      final cheerers = data['cheerers'] as List<dynamic>;
      return cheerers.cast<String>();
    } on ApiException {
      return [];
    }
  }
}
