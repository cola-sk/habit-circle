/// 全局任务模板（来自服务端 task_templates 表）
class TaskTemplateModel {
  final String id;
  final String key;
  final String name;
  final String emoji;
  final String colorHex;
  final int pointsPer15Min;
  final bool isTimeBased;
  final List<String> evidenceTypes; // ["image", "audio"]
  final int sortOrder;

  const TaskTemplateModel({
    required this.id,
    required this.key,
    required this.name,
    required this.emoji,
    required this.colorHex,
    required this.pointsPer15Min,
    required this.isTimeBased,
    required this.evidenceTypes,
    required this.sortOrder,
  });

  factory TaskTemplateModel.fromJson(Map<String, dynamic> data) =>
      TaskTemplateModel(
        id: data['id'] as String,
        key: data['key'] as String,
        name: data['name'] as String,
        emoji: data['emoji'] as String,
        colorHex: data['colorHex'] as String,
        pointsPer15Min: (data['pointsPer15Min'] as num).toInt(),
        isTimeBased: data['isTimeBased'] as bool,
        evidenceTypes: List<String>.from(data['evidenceTypes'] as List),
        sortOrder: (data['sortOrder'] as num).toInt(),
      );

  bool get supportsImage => evidenceTypes.contains('image');
  bool get supportsAudio => evidenceTypes.contains('audio');
  bool get supportsVideo => evidenceTypes.contains('video');
}

/// 用户已启用任务（来自服务端 user_tasks 表），内嵌模板详情
class UserTaskModel {
  final String id;
  final String userId;
  final TaskTemplateModel template;
  final DateTime createdAt;

  const UserTaskModel({
    required this.id,
    required this.userId,
    required this.template,
    required this.createdAt,
  });

  factory UserTaskModel.fromJson(Map<String, dynamic> data) => UserTaskModel(
        id: data['id'] as String,
        userId: data['userId'] as String,
        template: TaskTemplateModel.fromJson(
          data['template'] as Map<String, dynamic>,
        ),
        createdAt:
            DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
