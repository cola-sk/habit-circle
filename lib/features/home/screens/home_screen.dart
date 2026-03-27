import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../models/pet_model.dart';
import '../widgets/pet_display_widget.dart';
import '../widgets/hunger_bar_widget.dart';
import '../widgets/feed_button_widget.dart';
import '../widgets/today_summary_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(myPetProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final todayPoints = ref.watch(todayPointsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            title: Text(
              user != null ? '${user.childName}的宠物' : '我的宠物',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textSecondary,
                onPressed: () {},
              ),
            ],
          ),

          // ── 内容 ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Gap(8),

                petAsync.when(
                  loading: () => const _PetLoadingCard(),
                  error: (e, _) => _ErrorCard(message: e.toString()),
                  data: (pet) {
                    if (pet == null) {
                      return const _NoPetCard();
                    }
                    return Column(
                      children: [
                        // 宠物展示区
                        PetDisplayWidget(pet: pet)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: -0.1, end: 0),

                        const Gap(20),

                        // 状态条（饥饿值 + 成长进度）
                        HungerBarWidget(pet: pet)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms),

                        const Gap(16),

                        // 今日积分 + 喂食按钮
                        FeedButtonWidget(
                          pet: pet,
                          todayPoints: todayPoints,
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                        const Gap(24),

                        // 今日任务摘要
                        const TodaySummaryWidget()
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms),

                        const Gap(100), // BottomNav 空间
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),

      // FAB：快速开始任务
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/tasks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('开始任务', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PetLoadingCard extends StatelessWidget {
  const _PetLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('加载失败: $message',
            style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class _NoPetCard extends StatelessWidget {
  const _NoPetCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('🐾', style: TextStyle(fontSize: 48)),
            const Gap(16),
            const Text(
              '还没有宠物，去领养一只吧！',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () => context.go('/onboarding/pet'),
              child: const Text('领养宠物'),
            ),
          ],
        ),
      ),
    );
  }
}
