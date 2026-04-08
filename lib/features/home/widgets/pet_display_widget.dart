import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pet_species.dart';
import '../../../core/widgets/ip_video_widget.dart';
import '../../../models/pet_model.dart';

class PetDisplayWidget extends ConsumerWidget {
  final PetModel pet;

  const PetDisplayWidget({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(pet.hungerStatus);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // 背景装饰圆
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 宠物主体：优先播放 IP 视频，无视频时降级为 emoji
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIpImage(pet),
                const Gap(8),
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pet.hungerStatus.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 等级徽章
          Positioned(
            top: 16,
            left: 16,
            child: _LevelBadge(level: pet.level),
          ),

          // 成长阶段
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pet.growthStageDisplayName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpImage(PetModel pet) {
    final stage = WatermelonGrowthStageExtension.fromName(pet.growthStage);
    // 用 hungerStatus 推断今日是否有完成任务（happy/normal = 有积分 = 完成过任务）
    final hasCompletedToday = pet.hungerStatus == HungerStatus.happy ||
        pet.hungerStatus == HungerStatus.normal;
    final videoAsset = stage.ipVideoAsset(hasCompletedToday: hasCompletedToday);
    final emojiFontSize = _petSize(pet.level);

    if (videoAsset != null) {
      return IpVideoWidget(
        assetPath: videoAsset,
        size: 160, // 视频展示尺寸，独立于 emoji 字号
        fallbackEmoji: pet.species.emoji,
      );
    }
    // 该阶段暂无视频，降级为 emoji
    return Text(
      pet.species.emoji,
      style: TextStyle(fontSize: emojiFontSize),
    );
  }

  Color _statusColor(HungerStatus status) {
    switch (status) {
      case HungerStatus.happy:
        return AppColors.petHappy;
      case HungerStatus.normal:
        return AppColors.petNormal;
      case HungerStatus.hungry:
        return AppColors.petHungry;
      case HungerStatus.starving:
        return AppColors.petStarving;
      case HungerStatus.critical:
        return AppColors.petCritical;
    }
  }

  double _petSize(int level) {
    if (level >= 7) return 80;
    if (level >= 4) return 64;
    return 52;
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Lv.$level',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
