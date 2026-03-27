import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Text(
                '🍉',
                style: const TextStyle(fontSize: 80),
              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

              const Gap(16),

              Text(
                '养西瓜 🍉',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const Gap(8),

              Text(
                '坚持学习，把西瓜养大\n和小伙伴一起成长 🌱',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(flex: 3),

              // 功能亮点
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeatureChip(emoji: '📚', label: '学习打卡'),
                  _FeatureChip(emoji: '🐱', label: '宠物养成'),
                  _FeatureChip(emoji: '👥', label: '圈子互动'),
                ],
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

              const Spacer(flex: 2),

              // 按钮
              ElevatedButton(
                onPressed: () => context.go('/onboarding/auth'),
                child: const Text('开始使用'),
              ).animate().slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 800.ms,
                    duration: 400.ms,
                  ),

              const Gap(12),

              Text(
                '完全免费，无广告',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ).animate().fadeIn(delay: 1000.ms),

              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _FeatureChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
