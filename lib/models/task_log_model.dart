import '../core/constants/task_types.dart';

class TaskLogModel {
  final String id;
  final String uid;
  final TaskType taskType;
  final String taskName;
  final int durationMinutes;
  final int points;
  final bool completed;
  final String date;
  final DateTime createdAt;

  const TaskLogModel({
    required this.id,
    required this.uid,
    required this.taskType,
    required this.taskName,
    required this.durationMinutes,
    required this.points,
    required this.completed,
    required this.date,
    required this.createdAt,
  });

  factory TaskLogModel.fromJson(Map<String, dynamic> data) => TaskLogModel(
        id: data['id'] as String? ?? '',
        uid: data['userId'] as String? ?? '',
        taskType: TaskTypeExtension.fromString(data['taskType'] as String? ?? 'custom'),
        taskName: data['taskName'] as String? ?? '',
        durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
        points: (data['points'] as num?)?.toInt() ?? 0,
        completed: data['completed'] as bool? ?? true,
        date: data['date'] as String? ?? '',
        createdAt:
            DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  factory TaskLogModel.create({
    required String uid,
    required TaskType taskType,
    String? customName,
    required int durationMinutes,
  }) {
    final now = DateTime.now();
    final points = PointsCalculator.calculate(taskType, durationMinutes);
    return TaskLogModel(
      id: '',
      uid: uid,
      taskType: taskType,
      taskName: customName ?? taskType.displayName,
      durationMinutes: durationMinutes,
      points: points,
      completed: true,
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      createdAt: now,
    );
  }
}
