import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pet_species.dart';
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
            statusColor.withOpacity(0.15),
            AppColors.primary.withOpacity(0.08),
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
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 宠物主体（TODO: 替换为 Rive 动画）
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 宠物 emoji 占位（Rive 动画集成后替换）
                Text(
                  pet.species.emoji,
                  style: TextStyle(
                    fontSize: _petSize(pet.level),
                  ),
                ),
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
                    color: statusColor.withOpacity(0.2),
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _growthStageLabel(pet.growthStage),
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

  Color _statusColor(HungerStatus status) {
    switch (status) {
      case HungerStatus.happy:    return AppColors.petHappy;
      case HungerStatus.normal:   return AppColors.petNormal;
      case HungerStatus.hungry:   return AppColors.petHungry;
      case HungerStatus.starving: return AppColors.petStarving;
      case HungerStatus.critical: return AppColors.petCritical;
    }
  }

  double _petSize(int level) {
    if (level >= 7) return 80;
    if (level >= 4) return 64;
    return 52;
  }

  String _growthStageLabel(String stage) {
    switch (stage) {
      case 'juvenile': return '少年期';
      case 'adult':    return '成年期';
      default:         return '幼崽期';
    }
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
            color: AppColors.primary.withOpacity(0.3),
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
