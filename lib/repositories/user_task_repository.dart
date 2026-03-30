import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_task_model.dart';

final userTaskRepositoryProvider = Provider<UserTaskRepository>(
  (ref) => UserTaskRepository(ref.watch(apiClientProvider)),
);

class UserTaskRepository {
  final ApiClient _client;
  UserTaskRepository(this._client);

  /// 获取全局任务模板列表
  Future<List<TaskTemplateModel>> fetchTemplates() async {
    final list = await _client.getList(ApiEndpoints.taskTemplates);
    return list
        .map((e) => TaskTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取当前用户已启用任务列表（含模板详情）
  Future<List<UserTaskModel>> fetchUserTasks() async {
    final list = await _client.getList(ApiEndpoints.userTasks);
    return list
        .map((e) => UserTaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }



  /// 新增用户任务
  Future<UserTaskModel> addTask(String templateId) async {
    final data = await _client.post(
      ApiEndpoints.userTasks,
      body: {'templateId': templateId},
    );
    return UserTaskModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 删除用户任务
  Future<void> removeTask(String userTaskId) async {
    await _client.delete(ApiEndpoints.userTaskById(userTaskId));
  }
}
