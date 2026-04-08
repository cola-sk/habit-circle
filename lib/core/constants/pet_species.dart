/// 宠物种类
enum PetSpecies {
  cat, // 猫咪
  dog, // 小狗
  rabbit, // 兔子
  dragon, // 小龙（激励感强）
  hamster, // 仓鼠
}

extension PetSpeciesExtension on PetSpecies {
  String get displayName {
    switch (this) {
      case PetSpecies.cat:
        return '猫咪';
      case PetSpecies.dog:
        return '小狗';
      case PetSpecies.rabbit:
        return '兔子';
      case PetSpecies.dragon:
        return '小龙';
      case PetSpecies.hamster:
        return '仓鼠';
    }
  }

  String get emoji {
    switch (this) {
      case PetSpecies.cat:
        return '🐱';
      case PetSpecies.dog:
        return '🐶';
      case PetSpecies.rabbit:
        return '🐰';
      case PetSpecies.dragon:
        return '🐲';
      case PetSpecies.hamster:
        return '🐹';
    }
  }

  /// Rive 动画文件名
  String get riveAssetName {
    return 'assets/pets/$name.riv';
  }

  static PetSpecies fromString(String value) {
    return PetSpecies.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PetSpecies.cat,
    );
  }
}

/// 宠物饥饿状态
enum HungerStatus {
  happy, // 开心（今日积分 ≥ 80）
  normal, // 正常（60-79）
  hungry, // 饿了（30-59）
  starving, // 很饿（1-29）
  critical, // 奄奄一息（连续 2 天 0 分）
}

extension HungerStatusExtension on HungerStatus {
  String get displayName {
    switch (this) {
      case HungerStatus.happy:
        return '开心 😄';
      case HungerStatus.normal:
        return '正常 😊';
      case HungerStatus.hungry:
        return '饿了 😕';
      case HungerStatus.starving:
        return '很饿 😢';
      case HungerStatus.critical:
        return '奄奄一息 💀';
    }
  }

  String get riveStateName {
    switch (this) {
      case HungerStatus.happy:
        return 'happy';
      case HungerStatus.normal:
        return 'idle';
      case HungerStatus.hungry:
        return 'hungry';
      case HungerStatus.starving:
        return 'hungry';
      case HungerStatus.critical:
        return 'critical';
    }
  }

  static HungerStatus fromPoints(int todayPoints) {
    if (todayPoints >= 80) return HungerStatus.happy;
    if (todayPoints >= 60) return HungerStatus.normal;
    if (todayPoints >= 30) return HungerStatus.hungry;
    if (todayPoints >= 1) return HungerStatus.starving;
    return HungerStatus.critical;
  }

  static HungerStatus fromString(String value) {
    return HungerStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HungerStatus.normal,
    );
  }
}

/// 西瓜成长阶段（由累计任务积分驱动）
enum WatermelonGrowthStage {
  seed, // 种子期
  sprout, // 萌芽期
  flower, // 开花期
  fruit, // 结果期
  ripe, // 成熟期
}

extension WatermelonGrowthStageExtension on WatermelonGrowthStage {
  String get displayName {
    switch (this) {
      case WatermelonGrowthStage.seed:
        return '种子期';
      case WatermelonGrowthStage.sprout:
        return '萌芽期';
      case WatermelonGrowthStage.flower:
        return '开花期';
      case WatermelonGrowthStage.fruit:
        return '结果期';
      case WatermelonGrowthStage.ripe:
        return '成熟期';
    }
  }

  /// IP 形象动画视频路径，null 表示暂无视频（降级显示静态图）
  /// [hasCompletedToday] 今日是否有已完成的任务
  String? ipVideoAsset({required bool hasCompletedToday}) {
    switch (this) {
      case WatermelonGrowthStage.seed:
        return hasCompletedToday
            ? 'assets/animations/ip_zhongzi_happy.mp4'
            : 'assets/animations/ip_zhongzi_hungry.mp4';
      case WatermelonGrowthStage.sprout:
        return hasCompletedToday
            ? 'assets/animations/ip_faya_happy.mp4'
            : 'assets/animations/ip_faya_hungry.mp4';
      case WatermelonGrowthStage.flower:
        return hasCompletedToday
            ? 'assets/animations/ip_kaihua_happy.mp4'
            : 'assets/animations/ip_kaihua_hungry.mp4';
      case WatermelonGrowthStage.fruit:
        return hasCompletedToday
            ? 'assets/animations/ip_jieguo_happy.mp4'
            : 'assets/animations/ip_jieguo_hungry.mp4';
      case WatermelonGrowthStage.ripe:
        return 'assets/animations/ip_ripe.mp4'; // 成熟期不区分状态
    }
  }

  static WatermelonGrowthStage fromName(String value) {
    return WatermelonGrowthStage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WatermelonGrowthStage.seed,
    );
  }
}

/// 宠物成长等级阈值（累计积分）
class PetLevelThresholds {
  static const List<int> thresholds = [
    0, // Level 1
    200, // Level 2
    500, // Level 3
    1000, // Level 4
    1800, // Level 5
    3000, // Level 6
    4500, // Level 7
    6500, // Level 8
    9000, // Level 9
    12000, // Level 10
  ];

  /// 五大成长阶段阈值（累计积分）
  static const List<int> growthStageThresholds = [
    0, // seed
    200, // sprout
    1000, // flower
    1800, // fruit
    3000, // ripe
  ];

  static int levelFromPoints(int totalPoints) {
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (totalPoints >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  static int nextLevelThreshold(int currentLevel) {
    if (currentLevel >= 10) return thresholds.last;
    return thresholds[currentLevel];
  }

  /// 根据累计积分计算成长阶段（任务积分越高，阶段越高）
  static WatermelonGrowthStage growthStageFromPoints(int totalPoints) {
    for (int i = growthStageThresholds.length - 1; i >= 0; i--) {
      if (totalPoints >= growthStageThresholds[i]) {
        return WatermelonGrowthStage.values[i];
      }
    }
    return WatermelonGrowthStage.seed;
  }

  /// 向后兼容：保留字符串阶段接口
  static String growthStageName(int level) {
    final safeLevel = level.clamp(1, thresholds.length);
    final pointsAtLevel = thresholds[safeLevel - 1];
    return growthStageFromPoints(pointsAtLevel).name;
  }

  static String growthStageDisplayName(String stageKey) {
    return WatermelonGrowthStageExtension.fromName(stageKey).displayName;
  }
}
