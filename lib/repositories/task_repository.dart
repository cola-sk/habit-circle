import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/task_log_model.dart';
import '../core/constants/task_types.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(apiClientProvider)),
);

class TaskRepository {
  final ApiClient _client;
  TaskRepository(this._client);

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<TaskLogModel>> fetchTodayLogs() => _fetchTodayLogs();

  Future<List<TaskLogModel>> _fetchTodayLogs() async {
    try {
      final data = await _client.get(
        ApiEndpoints.tasks,
        queryParameters: {'date': _todayDate},
      );
      final logs = data['logs'] as List<dynamic>;
      return logs
          .map((l) => TaskLogModel.fromJson(l as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return [];
    }
  }

  Future<TaskLogModel> saveLog(TaskLogModel log) async {
    final data = await _client.post(ApiEndpoints.tasks, body: {
      'taskType': log.taskType.name,
      'taskName': log.taskName,
      'durationMinutes': log.durationMinutes,
    });
    return TaskLogModel.fromJson(data);
  }

  Future<void> uploadEvidence(
      String taskId, List<int> bytes, String filename) async {
    final file = MultipartFile.fromBytes(bytes, filename: filename);
    final formData = FormData.fromMap({'file': file});
    await _client.postFormData(
      ApiEndpoints.taskEvidence(taskId),
      formData: formData,
    );
  }
}
