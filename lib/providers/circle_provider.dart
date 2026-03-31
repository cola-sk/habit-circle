import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/circle_model.dart';
import '../repositories/circle_repository.dart';
import 'auth_provider.dart';

/// 当前用户所在圈子
final myCircleProvider = FutureProvider<CircleModel?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final circleId = user?.circleId;
  if (circleId == null) return Future.value(null);
  return ref.watch(circleRepositoryProvider).fetchCircle(circleId);
});

/// 全部圈子（公开，无需登录）
final allCirclesProvider = FutureProvider<List<CircleModel>>((ref) {
  return ref.watch(circleRepositoryProvider).fetchAllCircles();
});

/// 创建/加入圈子操作
final circleSetupProvider =
    StateNotifierProvider<CircleSetupNotifier, AsyncValue<void>>(
  (ref) => CircleSetupNotifier(ref),
);

class CircleSetupNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CircleSetupNotifier(this._ref) : super(const AsyncData(null));

  Future<void> createCircle(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ref.read(circleRepositoryProvider).createCircle(name: name),
    );
  }

  Future<bool> joinCircle(String inviteCode) async {
    state = const AsyncLoading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      success = await _ref
          .read(circleRepositoryProvider)
          .joinCircleByCode(inviteCode);
    });
    return success;
  }

  Future<bool> joinCircleById(String circleId) async {
    state = const AsyncLoading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      success = await _ref
          .read(circleRepositoryProvider)
          .joinCircleById(circleId);
      if (success) {
        _ref.invalidate(myCircleProvider);
        _ref.invalidate(allCirclesProvider);
        _ref.invalidate(currentUserProvider);
      }
    });
    return success;
  }
}
