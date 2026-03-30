import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_log_model.dart';
import '../repositories/task_repository.dart';
import '../core/constants/task_types.dart';
import 'auth_provider.dart';

/// 今日任务记录（轮询流）
final todayTaskLogsProvider = StreamProvider<List<TaskLogModel>>((ref) {
  final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
  if (!isLoggedIn) return Stream.value(const []);
  return ref.watch(taskRepositoryProvider).watchTodayLogs();
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

  Future<void> submit({
    required TaskType taskType,
    String? customName,
    required int durationMinutes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final log = TaskLogModel.create(
        uid: '',
        taskType: taskType,
        customName: customName,
        durationMinutes: durationMinutes,
      );
      await _ref.read(taskRepositoryProvider).saveLog(log);
    });
  }

  /// 通过模板 key 提交任务（动态任务列表使用）
  Future<void> submitByTemplate({
    required String templateKey,
    required String templateName,
    required int durationMinutes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final taskType = TaskTypeExtension.fromString(templateKey);
      final log = TaskLogModel.create(
        uid: '',
        taskType: taskType,
        customName: templateName,
        durationMinutes: durationMinutes,
      );
      await _ref.read(taskRepositoryProvider).saveLog(log);
    });
  }
}
