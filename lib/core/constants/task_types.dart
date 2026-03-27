/// 任务类型枚举
enum TaskType {
  reading,   // 自主阅读
  piano,     // 练琴
  english,   // 英语绘本
  preview,   // 课程预习
  homework,  // 完成作业
  exercise,  // 户外运动
  custom,    // 自定义任务
}

extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.reading:  return '自主阅读';
      case TaskType.piano:    return '练琴';
      case TaskType.english:  return '英语绘本';
      case TaskType.preview:  return '课程预习';
      case TaskType.homework: return '完成作业';
      case TaskType.exercise: return '户外运动';
      case TaskType.custom:   return '自定义任务';
    }
  }

  String get emoji {
    switch (this) {
      case TaskType.reading:  return '📚';
      case TaskType.piano:    return '🎹';
      case TaskType.english:  return '🌍';
      case TaskType.preview:  return '📖';
      case TaskType.homework: return '✏️';
      case TaskType.exercise: return '⚽';
      case TaskType.custom:   return '⭐';
    }
  }

  /// 每 15 分钟的基础积分（homework 是固定值）
  int get pointsPer15Min {
    switch (this) {
      case TaskType.reading:  return 10;
      case TaskType.piano:    return 15;
      case TaskType.english:  return 12;
      case TaskType.preview:  return 10;
      case TaskType.homework: return 20; // 固定积分
      case TaskType.exercise: return 8;
      case TaskType.custom:   return 10;
    }
  }

  /// 是否按时长计分（false 表示完成即得固定积分）
  bool get isTimeBased {
    return this != TaskType.homework;
  }

  String get colorHex {
    switch (this) {
      case TaskType.reading:  return '#4FC3F7';
      case TaskType.piano:    return '#CE93D8';
      case TaskType.english:  return '#80CBC4';
      case TaskType.preview:  return '#A5D6A7';
      case TaskType.homework: return '#FFCC80';
      case TaskType.exercise: return '#EF9A9A';
      case TaskType.custom:   return '#B0BEC5';
    }
  }

  static TaskType fromString(String value) {
    return TaskType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskType.custom,
    );
  }
}

/// 积分计算工具
class PointsCalculator {
  /// 根据时长（分钟）和任务类型计算积分
  static int calculate(TaskType type, int durationMinutes) {
    if (!type.isTimeBased) return type.pointsPer15Min;
    if (durationMinutes <= 0) return 0;
    final units = (durationMinutes / 15).floor();
    return units * type.pointsPer15Min;
  }
}
