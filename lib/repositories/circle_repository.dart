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

  Future<CircleModel?> fetchCircle(String circleId) async {
    try {
      final data = await _client.get(ApiEndpoints.circleById(circleId));
      return CircleModel.fromJson(data);
    } on ApiException {
      return null;
    }
  }

  /// 公开获取所有圈子列表（无需登录）
  Future<List<CircleModel>> fetchAllCircles() async {
    try {
      final data = await _client.get(ApiEndpoints.circles);
      final list = data['circles'] as List<dynamic>? ?? [];
      return list
          .map((c) => CircleModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return [];
    }
  }

  Future<void> createCircle({required String name}) async {
    await _client.post(ApiEndpoints.circles, body: {'name': name});
  }

  /// 通过邀请码加入
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

  /// 直接按圈子 ID 加入（不需要邀请码）
  Future<bool> joinCircleById(String circleId) async {
    try {
      await _client.post(ApiEndpoints.circleJoinById(circleId), body: {});
      return true;
    } on ApiException {
      return false;
    }
  }
}
