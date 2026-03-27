import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 主色调：温暖活泼，适合儿童
  static const primary = Color(0xFF6C63FF);        // 紫色主色
  static const primaryLight = Color(0xFF9D96FF);
  static const primaryDark = Color(0xFF4A43CC);

  static const secondary = Color(0xFFFF6B6B);      // 活力红
  static const accent = Color(0xFFFFD93D);          // 明亮黄

  // 宠物状态色
  static const petHappy = Color(0xFF4CAF50);        // 绿：开心
  static const petNormal = Color(0xFF8BC34A);       // 浅绿：正常
  static const petHungry = Color(0xFFFF9800);       // 橙：饿了
  static const petStarving = Color(0xFFF44336);     // 红：很饿
  static const petCritical = Color(0xFF9E9E9E);     // 灰：奄奄一息

  // 背景
  static const backgroundLight = Color(0xFFF8F7FF);
  static const backgroundCard = Color(0xFFFFFFFF);
  static const backgroundDark = Color(0xFF1A1A2E);

  // 文字
  static const textPrimary = Color(0xFF2C2C54);
  static const textSecondary = Color(0xFF6B6B8A);
  static const textLight = Color(0xFFFFFFFF);

  // 任务类型色
  static const taskReading = Color(0xFF4FC3F7);
  static const taskPiano = Color(0xFFCE93D8);
  static const taskEnglish = Color(0xFF80CBC4);
  static const taskPreview = Color(0xFFA5D6A7);
  static const taskHomework = Color(0xFFFFCC80);
  static const taskExercise = Color(0xFFEF9A9A);
  static const taskCustom = Color(0xFFB0BEC5);
}
