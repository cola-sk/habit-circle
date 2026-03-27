import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pet_species.dart';
import '../../../models/pet_model.dart';

class HungerBarWidget extends StatelessWidget {
  final PetModel pet;

  const HungerBarWidget({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final nextThreshold = PetLevelThresholds.nextLevelThreshold(pet.level);
    final currentThreshold =
        PetLevelThresholds.thresholds[(pet.level - 1).clamp(0, 9)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 成长进度
        _BarRow(
          label: '成长值',
          icon: '⭐',
          progress: pet.levelProgress,
          color: AppColors.accent,
          trailingText:
              'Lv.${pet.level}  ${pet.totalPoints - currentThreshold}/${nextThreshold - currentThreshold}',
        ),

        const Gap(10),

        // 饥饿状态
        _HungerIndicator(status: pet.hungerStatus),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final String icon;
  final double progress;
  final Color color;
  final String trailingText;

  const _BarRow({
    required this.label,
    required this.icon,
    required this.progress,
    required this.color,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const Gap(6),
                Text(label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
              ]),
              Text(trailingText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFEEEEFF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _HungerIndicator extends StatelessWidget {
  final HungerStatus status;

  const _HungerIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text('🍗', style: const TextStyle(fontSize: 16)),
          const Gap(6),
          const Text('今日状态',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _color(HungerStatus s) {
    switch (s) {
      case HungerStatus.happy:    return AppColors.petHappy;
      case HungerStatus.normal:   return AppColors.petNormal;
      case HungerStatus.hungry:   return AppColors.petHungry;
      case HungerStatus.starving: return AppColors.petStarving;
      case HungerStatus.critical: return AppColors.petCritical;
    }
  }
}
