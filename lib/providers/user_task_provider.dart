import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_task_model.dart';
import '../repositories/user_task_repository.dart';
import 'auth_provider.dart';

/// 全局任务模板
final taskTemplatesProvider =
    FutureProvider<List<TaskTemplateModel>>((ref) async {
  final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
  if (!isLoggedIn) return [];
  return ref.read(userTaskRepositoryProvider).fetchTemplates();
});

/// 用户已启用任务
final userTasksProvider = FutureProvider<List<UserTaskModel>>((ref) {
  final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
  if (!isLoggedIn) return Future.value([]);
  return ref.watch(userTaskRepositoryProvider).fetchUserTasks();
});

/// 管理用户任务（新增/删除）
final manageUserTaskProvider =
    StateNotifierProvider<ManageUserTaskNotifier, AsyncValue<void>>(
  (ref) => ManageUserTaskNotifier(ref),
);

class ManageUserTaskNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ManageUserTaskNotifier(this._ref) : super(const AsyncData(null));

  Future<void> addTask(String templateId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ref.read(userTaskRepositoryProvider).addTask(templateId),
    );
    // 刷新用户任务列表
    _ref.invalidate(userTasksProvider);
  }

  Future<void> removeTask(String userTaskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ref.read(userTaskRepositoryProvider).removeTask(userTaskId),
    );
    _ref.invalidate(userTasksProvider);
  }
}
