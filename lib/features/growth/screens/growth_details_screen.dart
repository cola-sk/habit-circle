import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/pet_species.dart';
import '../../../core/widgets/ip_video_widget.dart';
import '../../../models/pet_model.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/task_provider.dart';

class GrowthDetailsScreen extends ConsumerWidget {
  const GrowthDetailsScreen({super.key});

  static const List<_GrowthStageMeta> _stages = [
    _GrowthStageMeta(
      key: 'seed',
      title: '种子期',
      description: '埋下学习的第一颗种子',
      assetPath: 'assets/images/growth/seed.png',
      icon: Icons.grain,
    ),
    _GrowthStageMeta(
      key: 'sprout',
      title: '萌芽期',
      description: '开始出现小芽，习惯逐渐稳定',
      assetPath: 'assets/images/growth/sprout.png',
      icon: Icons.spa,
    ),
    _GrowthStageMeta(
      key: 'flower',
      title: '开花期',
      description: '坚持积累，迎来开花阶段',
      assetPath: 'assets/images/growth/flower.png',
      icon: Icons.local_florist,
    ),
    _GrowthStageMeta(
      key: 'fruit',
      title: '结果期',
      description: '学习成果开始显现',
      assetPath: 'assets/images/growth/fruit.png',
      icon: Icons.eco,
    ),
    _GrowthStageMeta(
      key: 'ripe',
      title: '成熟期',
      description: '西瓜成熟，达成阶段目标',
      assetPath: 'assets/images/growth/ripe.png',
      icon: Icons.workspace_premium,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(myPetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF8FE),
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('错误：$e')),
          data: (pet) {
            if (pet == null) {
              return const Center(child: Text('还没有西瓜，先去创建一个吧'));
            }
            final hasCompletedToday =
                ref.watch(todayTaskLogsProvider).valueOrNull?.any((e) => e.completed) ?? false;
            return _GrowthContent(
              pet: pet,
              stages: _stages,
              hasCompletedToday: hasCompletedToday,
            );
          },
        ),
      ),
    );
  }
}

class _GrowthContent extends StatelessWidget {
  final PetModel pet;
  final List<_GrowthStageMeta> stages;
  final bool hasCompletedToday;

  const _GrowthContent({
    required this.pet,
    required this.stages,
    required this.hasCompletedToday,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentStageIndex(pet.growthStage, stages);
    final currentStage = stages[currentIndex];
    const thresholds = PetLevelThresholds.growthStageThresholds;

    final currentThreshold = thresholds[currentIndex];
    final isMaxStage = currentIndex == stages.length - 1;
    final nextThreshold =
        isMaxStage ? thresholds.last : thresholds[currentIndex + 1];
    final nextStageTitle = isMaxStage ? null : stages[currentIndex + 1].title;

    final stageRange = (nextThreshold - currentThreshold).clamp(1, 1 << 30);
    final stageProgress = isMaxStage
        ? 1.0
        : ((pet.totalPoints - currentThreshold) / stageRange).clamp(0.0, 1.0);
    final pointsToNext = isMaxStage
        ? 0
        : (nextThreshold - pet.totalPoints).clamp(0, nextThreshold);
    final totalProgress = (pet.totalPoints / thresholds.last).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            onBack: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            seeds: pet.totalPoints,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2F9),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF91F78E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '当前阶段',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF005E17),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentStage.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB21D27),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStage.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF545D62),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: _buildStageHero(currentStage.key),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x1AA5AEB4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMaxStage
                            ? '已达到最高阶段“成熟期”'
                            : '距离下一阶段“$nextStageTitle”还差',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF545D62),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMaxStage ? '已完成全部成长' : '$pointsToNext 西瓜子',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB21D27),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: stageProgress,
                          backgroundColor: const Color(0xFFD8E4EC),
                          color: const Color(0xFFB21D27),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '当前阶段进度 ${(stageProgress * 100).round()}% · 总进度 ${(totalProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006B1B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              '成长全过程',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF273034),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final state = index < currentIndex
                ? _StageStatus.completed
                : index == currentIndex
                    ? _StageStatus.active
                    : _StageStatus.locked;
            final pointsToUnlock = index <= currentIndex
                ? 0
                : (thresholds[index] - pet.totalPoints)
                    .clamp(0, thresholds[index]);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StageCard(
                index: index + 1,
                stage: stage,
                status: state,
                pointsToUnlock: pointsToUnlock,
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.go('/tasks'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB21D27),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              '记录今日成长行为',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageHero(String stageKey) {
    final stage = WatermelonGrowthStageExtension.fromName(stageKey);
    final videoAsset = stage.ipVideoAsset(hasCompletedToday: hasCompletedToday);
    if (videoAsset != null) {
      return IpVideoWidget(
        assetPath: videoAsset,
        size: 220,
        fallbackEmoji: '🌱',
      );
    }
    // 该阶段暂无视频，降级为静态图
    final meta = stages.firstWhere(
      (s) => s.key == stageKey,
      orElse: () => stages.first,
    );
    return Image.asset(meta.assetPath, fit: BoxFit.contain);
  }

  static int _currentStageIndex(
      String currentKey, List<_GrowthStageMeta> stages) {
    final idx = stages.indexWhere((stage) => stage.key == currentKey);
    return idx < 0 ? 0 : idx;
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final int seeds;

  const _TopBar({
    required this.onBack,
    required this.seeds,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF273034),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '西瓜成长图鉴',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB21D27),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.energy_savings_leaf,
                size: 16,
                color: Color(0xFF624D00),
              ),
              const SizedBox(width: 6),
              Text(
                '$seeds 西瓜子',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF273034),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  final int index;
  final _GrowthStageMeta stage;
  final _StageStatus status;
  final int pointsToUnlock;

  const _StageCard({
    required this.index,
    required this.stage,
    required this.status,
    required this.pointsToUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == _StageStatus.completed;
    final isActive = status == _StageStatus.active;
    final isLocked = status == _StageStatus.locked;

    final backgroundColor = isActive
        ? const Color(0x22FF7671)
        : isCompleted
            ? Colors.white
            : const Color(0xFFD8E4EC);
    final borderColor = isActive
        ? const Color(0xFFB21D27)
        : isCompleted
            ? const Color(0x55006B1B)
            : const Color(0x55A5AEB4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: Opacity(
        opacity: isLocked ? 0.78 : 1,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFB21D27) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(stage.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${stage.title}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isActive
                          ? const Color(0xFFB21D27)
                          : const Color(0xFF273034),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? const Color(0xFFB21D27)
                          : const Color(0xFF545D62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _statusIcon(),
              color: isActive
                  ? const Color(0xFFB21D27)
                  : isCompleted
                      ? const Color(0xFF006B1B)
                      : const Color(0xFF6F787D),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon() {
    switch (status) {
      case _StageStatus.completed:
        return Icons.check_circle;
      case _StageStatus.active:
        return Icons.priority_high;
      case _StageStatus.locked:
        return Icons.lock;
    }
  }

  String _subtitleText() {
    switch (status) {
      case _StageStatus.completed:
        return '已达成';
      case _StageStatus.active:
        return '正在成长中...';
      case _StageStatus.locked:
        if (pointsToUnlock > 0) return '还需 $pointsToUnlock 西瓜子';
        return '尚未开启';
    }
  }
}

class _GrowthStageMeta {
  final String key;
  final String title;
  final String description;
  final String assetPath;
  final IconData icon;

  const _GrowthStageMeta({
    required this.key,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.icon,
  });
}

enum _StageStatus { completed, active, locked }
