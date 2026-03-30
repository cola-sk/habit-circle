import '../core/constants/pet_species.dart';

class PetModel {
  final String ownerId;
  final String ownerName; // 孩子昵称，圈子广场用于区分是谁的西瓜
  final String name;
  final PetSpecies species;
  final int level;
  final int totalPoints;
  final DateTime? lastFedAt;
  final HungerStatus hungerStatus;
  final DateTime createdAt;

  const PetModel({
    required this.ownerId,
    this.ownerName = '',
    required this.name,
    required this.species,
    required this.level,
    required this.totalPoints,
    this.lastFedAt,
    required this.hungerStatus,
    required this.createdAt,
  });

  factory PetModel.fromJson(Map<String, dynamic> data) => PetModel(
        ownerId: data['ownerId'] as String? ?? '',
        ownerName: data['ownerName'] as String? ?? '',
        name: data['name'] as String? ?? '我的宠物',
        species:
            PetSpeciesExtension.fromString(data['species'] as String? ?? 'cat'),
        level: (data['level'] as num?)?.toInt() ?? 1,
        totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
        lastFedAt: data['lastFedAt'] != null
            ? DateTime.tryParse(data['lastFedAt'] as String)
            : null,
        hungerStatus: HungerStatusExtension.fromString(
            data['hungerStatus'] as String? ?? 'normal'),
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  /// 成长阶段 key：seed/sprout/vine/flower/fruit/ripe
  String get growthStage =>
      PetLevelThresholds.growthStageFromPoints(totalPoints).name;

  /// 成长阶段中文：种子期/萌芽期/抽藤期/开花期/结果期/成熟期
  String get growthStageDisplayName =>
      PetLevelThresholds.growthStageFromPoints(totalPoints).displayName;

  int get pointsToNextLevel {
    final nextThreshold = PetLevelThresholds.nextLevelThreshold(level);
    return (nextThreshold - totalPoints).clamp(0, nextThreshold);
  }

  double get levelProgress {
    if (level >= 10) return 1.0;
    final currentThreshold = PetLevelThresholds.thresholds[level - 1];
    final nextThreshold = PetLevelThresholds.thresholds[level];
    final progress = totalPoints - currentThreshold;
    final range = nextThreshold - currentThreshold;
    return (progress / range).clamp(0.0, 1.0);
  }

  PetModel copyWith({
    String? ownerName,
    String? name,
    int? level,
    int? totalPoints,
    DateTime? lastFedAt,
    HungerStatus? hungerStatus,
  }) =>
      PetModel(
        ownerId: ownerId,
        ownerName: ownerName ?? this.ownerName,
        name: name ?? this.name,
        species: species,
        level: level ?? this.level,
        totalPoints: totalPoints ?? this.totalPoints,
        lastFedAt: lastFedAt ?? this.lastFedAt,
        hungerStatus: hungerStatus ?? this.hungerStatus,
        createdAt: createdAt,
      );
}
