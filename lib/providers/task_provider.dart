import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_log_model.dart';
import '../repositories/task_repository.dart';
import '../core/constants/task_types.dart';
import 'auth_provider.dart';
import 'pet_provider.dart';
import 'circle_provider.dart';

/// 今日任务记录
final todayTaskLogsProvider = FutureProvider<List<TaskLogModel>>((ref) {
  final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
  if (!isLoggedIn) return Future.value(const []);
  return ref.watch(taskRepositoryProvider).fetchTodayLogs();
});

/// 今日累计积分
final todayPointsProvider = Provider<int>((ref) {
  final logs = ref.watch(todayTaskLogsProvider).valueOrNull ?? [];
  return logs.fold(0, (sum, log) => sum + log.points);
});

/// 提交完成任务
final submitTaskProvider =
    StateNotifierProvider<SubmitTaskNotifier, AsyncValue<void>>(
  (ref) => SubmitTaskNotifier(ref),
);

class SubmitTaskNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SubmitTaskNotifier(this._ref) : super(const AsyncData(null));

  Future<TaskLogModel> submit({
    required TaskType taskType,
    String? customName,
    required int durationMinutes,
  }) async {
    state = const AsyncLoading();
    final log = TaskLogModel.create(
      uid: '',
      taskType: taskType,
      customName: customName,
      durationMinutes: durationMinutes,
    );
    try {
      final (created, pet) =
          await _ref.read(taskRepositoryProvider).saveLog(log);
      state = const AsyncData(null);
      _ref.invalidate(todayTaskLogsProvider);
      // 直接用服务端返回的最新 pet 覆盖缓存，无需等待重新 fetch
      if (pet != null) {
        _ref.read(myPetProvider.notifier).updateFromServer(pet);
      } else {
        _ref.invalidate(myPetProvider);
      }
      _ref.invalidate(circlePetsProvider);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 通过模板 key 提交任务（动态任务列表使用）
  Future<TaskLogModel> submitByTemplate({
    required String templateKey,
    required String templateName,
    required int durationMinutes,
  }) async {
    state = const AsyncLoading();
    final taskType = TaskTypeExtension.fromString(templateKey);
    final log = TaskLogModel.create(
      uid: '',
      taskType: taskType,
      customName: templateName,
      durationMinutes: durationMinutes,
    );
    try {
      final (created, pet) =
          await _ref.read(taskRepositoryProvider).saveLog(log);
      state = const AsyncData(null);
      _ref.invalidate(todayTaskLogsProvider);
      // 直接用服务端返回的最新 pet 覆盖缓存，无需等待重新 fetch
      if (pet != null) {
        _ref.read(myPetProvider.notifier).updateFromServer(pet);
      } else {
        _ref.invalidate(myPetProvider);
      }
      _ref.invalidate(circlePetsProvider);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
