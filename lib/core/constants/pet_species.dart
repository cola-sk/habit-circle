/// 宠物种类
enum PetSpecies {
  cat,    // 猫咪
  dog,    // 小狗
  rabbit, // 兔子
  dragon, // 小龙（激励感强）
  hamster,// 仓鼠
}

extension PetSpeciesExtension on PetSpecies {
  String get displayName {
    switch (this) {
      case PetSpecies.cat:     return '猫咪';
      case PetSpecies.dog:     return '小狗';
      case PetSpecies.rabbit:  return '兔子';
      case PetSpecies.dragon:  return '小龙';
      case PetSpecies.hamster: return '仓鼠';
    }
  }

  String get emoji {
    switch (this) {
      case PetSpecies.cat:     return '🐱';
      case PetSpecies.dog:     return '🐶';
      case PetSpecies.rabbit:  return '🐰';
      case PetSpecies.dragon:  return '🐲';
      case PetSpecies.hamster: return '🐹';
    }
  }

  /// Rive 动画文件名
  String get riveAssetName {
    return 'assets/pets/${name}.riv';
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
  happy,    // 开心（今日积分 ≥ 80）
  normal,   // 正常（60-79）
  hungry,   // 饿了（30-59）
  starving, // 很饿（1-29）
  critical, // 奄奄一息（连续 2 天 0 分）
}

extension HungerStatusExtension on HungerStatus {
  String get displayName {
    switch (this) {
      case HungerStatus.happy:    return '开心 😄';
      case HungerStatus.normal:   return '正常 😊';
      case HungerStatus.hungry:   return '饿了 😕';
      case HungerStatus.starving: return '很饿 😢';
      case HungerStatus.critical: return '奄奄一息 💀';
    }
  }

  String get riveStateName {
    switch (this) {
      case HungerStatus.happy:    return 'happy';
      case HungerStatus.normal:   return 'idle';
      case HungerStatus.hungry:   return 'hungry';
      case HungerStatus.starving: return 'hungry';
      case HungerStatus.critical: return 'critical';
    }
  }

  static HungerStatus fromPoints(int todayPoints) {
    if (todayPoints >= 80) return HungerStatus.happy;
    if (todayPoints >= 60) return HungerStatus.normal;
    if (todayPoints >= 30) return HungerStatus.hungry;
    if (todayPoints >= 1)  return HungerStatus.starving;
    return HungerStatus.critical;
  }

  static HungerStatus fromString(String value) {
    return HungerStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HungerStatus.normal,
    );
  }
}

/// 宠物成长等级阈值（累计积分）
class PetLevelThresholds {
  static const List<int> thresholds = [
    0,    // Level 1
    200,  // Level 2
    500,  // Level 3
    1000, // Level 4
    1800, // Level 5
    3000, // Level 6
    4500, // Level 7
    6500, // Level 8
    9000, // Level 9
    12000, // Level 10
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

  /// 成长阶段：1-3 幼崽，4-6 少年，7-10 成年
  static String growthStageName(int level) {
    if (level <= 3) return 'baby';
    if (level <= 6) return 'juvenile';
    return 'adult';
  }
}
