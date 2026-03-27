import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/pet_model.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/task_provider.dart';

class FeedButtonWidget extends ConsumerWidget {
  final PetModel pet;
  final int todayPoints;

  const FeedButtonWidget({
    super.key,
    required this.pet,
    required this.todayPoints,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedPetProvider);
    final isLoading = feedState is AsyncLoading;

    // 判断今天是否已喂食
    final now = DateTime.now();
    final lastFed = pet.lastFedAt;
    final alreadyFedToday = lastFed != null &&
        lastFed.year == now.year &&
        lastFed.month == now.month &&
        lastFed.day == now.day;

    final canFeed = todayPoints > 0 && !alreadyFedToday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: canFeed
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: canFeed ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: canFeed
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 积分展示
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日积分',
                style: TextStyle(
                  fontSize: 13,
                  color: canFeed
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
              const Gap(4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$todayPoints',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: canFeed ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      '分',
                      style: TextStyle(
                        fontSize: 14,
                        color: canFeed
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // 喂食按钮
          if (alreadyFedToday)
            _FedTodayChip()
          else
            _FeedButton(
              points: todayPoints,
              isLoading: isLoading,
              onTap: canFeed
                  ? () => ref.read(feedPetProvider.notifier).feed(todayPoints)
                  : null,
            ),
        ],
      ),
    );
  }
}

class _FeedButton extends StatelessWidget {
  final int points;
  final bool isLoading;
  final VoidCallback? onTap;

  const _FeedButton({
    required this.points,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.white
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                children: [
                  const Text('🍗', style: TextStyle(fontSize: 18)),
                  const Gap(6),
                  Text(
                    onTap != null ? '喂食' : '没积分',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: onTap != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    ).animate(target: onTap != null ? 1 : 0).shake(
          duration: 200.ms,
          hz: 3,
          rotation: 0.02,
        );
  }
}

class _FedTodayChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.petHappy.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Text('✅', style: TextStyle(fontSize: 16)),
          Gap(6),
          Text(
            '已喂食',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.petHappy,
            ),
          ),
        ],
      ),
    );
  }
}
