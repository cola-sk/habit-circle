import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/pet_species.dart';
import '../../../core/widgets/ip_video_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../models/pet_model.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(myPetProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final todayPoints = ref.watch(todayPointsProvider);
    final taskLogs = ref.watch(todayTaskLogsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF8FE),
      body: SafeArea(
        child: petAsync.when(
          loading: () => const _PetLoadingCard(),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (pet) {
            if (pet == null) return const _NoPetCard();
            return _FarmHomeBody(
              childName: user?.childName,
              pet: pet,
              todayPoints: todayPoints,
              logsCount: taskLogs.length,
              completedCount: taskLogs.where((e) => e.completed).length,
              onGoTasks: () => context.go('/tasks'),
            );
          },
        ),
      ),
    );
  }
}

class _FarmHomeBody extends ConsumerWidget {
  final String? childName;
  final PetModel pet;
  final int todayPoints;
  final int logsCount;
  final int completedCount;
  final VoidCallback onGoTasks;

  const _FarmHomeBody({
    required this.childName,
    required this.pet,
    required this.todayPoints,
    required this.logsCount,
    required this.completedCount,
    required this.onGoTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskTarget = logsCount < 5 ? 5 : logsCount;
    final clampedDone = completedCount.clamp(0, taskTarget);
    final taskProgress = taskTarget == 0 ? 0.0 : clampedDone / taskTarget;
    final sizeKg = (0.4 + pet.level * 0.2).clamp(0.6, 9.9).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopHeader(seedPoints: pet.totalPoints)
              .animate()
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEFF8FE), Colors.white],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 36,
                  left: 20,
                  child: Icon(Icons.cloud, size: 56, color: Colors.white70),
                ),
                const Positioned(
                  top: 84,
                  right: 20,
                  child: Icon(Icons.cloud, size: 72, color: Color(0xCCFFFFFF)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB21D27),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'LEVEL ${pet.level}: ${pet.growthStageDisplayName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        childName == null ? '我的小西瓜' : '${childName!}的小西瓜',
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1.08,
                          color: Color(0xFF273034),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 12,
                              child: Container(
                                width: 220,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0x25273034),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                            _buildPetDisplay(pet.growthStage, completedCount > 0)
                                .animate()
                                .fadeIn(duration: 450.ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  end: const Offset(1, 1),
                                  duration: 500.ms,
                                ),
                            Positioned(
                              right: 28,
                              top: 24,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDD34D),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  size: 20,
                                  color: Color(0xFF5C4900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Size',
                              icon: Icons.fitness_center,
                              accentColor: const Color(0xFF006B1B),
                              valueText: sizeKg.toStringAsFixed(1),
                              suffixText: 'kg',
                              progress: pet.levelProgress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Tasks',
                              icon: Icons.assignment_turned_in,
                              accentColor: const Color(0xFFB21D27),
                              valueText: '$clampedDone',
                              suffixText: '/ $taskTarget',
                              progress: taskProgress,
                              segmented: true,
                              segments: taskTarget,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (pet.canHarvest) ...[
            _HarvestBanner(pet: pet).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 14),
          ],
          _TodayGrowthCard(todayPoints: todayPoints),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickInfoCard(
                  icon: Icons.wb_sunny,
                  title: '今日任务',
                  subtitle: '已完成 $clampedDone 项',
                  backgroundColor: const Color(0x30FDD34D),
                  borderColor: const Color(0x66FDD34D),
                  iconBackground: const Color(0xFF705900),
                  textColor: const Color(0xFF5C4900),
                  onTap: onGoTasks,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickInfoCard(
                  icon: Icons.water_drop,
                  iconWidget: _StatusIcon(todayPoints: todayPoints),
                  title: '水分状态',
                  subtitle: _waterLevelText(todayPoints),
                  backgroundColor: const Color(0x3091F78E),
                  borderColor: const Color(0x6691F78E),
                  iconBackground: const Color(0xFF006B1B),
                  textColor: const Color(0xFF005E17),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '完成任务可让西瓜长得更大 🍉',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F787D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static String _waterLevelText(int todayPoints) {
    if (todayPoints >= 60) return 'Water Level: OK';
    if (todayPoints >= 30) return 'Water Level: LOW';
    return 'Water Level: CRITICAL';
  }

  static Widget _buildPetDisplay(String growthStage, bool hasCompletedToday) {
    final stage = WatermelonGrowthStageExtension.fromName(growthStage);
    final videoAsset = stage.ipVideoAsset(hasCompletedToday: hasCompletedToday);
    if (videoAsset != null) {
      return IpVideoWidget(
        assetPath: videoAsset,
        size: 220,
        fallbackEmoji: '🌱',
      );
    }
    return Image.asset(
      _growthImageAsset(growthStage),
      width: 220,
      fit: BoxFit.contain,
    );
  }

  static String _growthImageAsset(String growthStage) {
    switch (growthStage) {
      case 'seed':
        return 'assets/images/growth/seed.png';
      case 'sprout':
        return 'assets/images/growth/sprout.png';
      case 'flower':
        return 'assets/images/growth/flower.png';
      case 'fruit':
        return 'assets/images/growth/fruit.png';
      case 'ripe':
        return 'assets/images/growth/ripe.png';
      default:
        return 'assets/images/growth/seed.png';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final int todayPoints;

  const _StatusIcon({required this.todayPoints});

  @override
  Widget build(BuildContext context) {
    final String asset;
    if (todayPoints >= 60) {
      asset = 'assets/images/status/happy.png';
    } else if (todayPoints >= 30) {
      asset = 'assets/images/status/hungry.png';
    } else {
      asset = 'assets/images/status/starving.png';
    }
    return SizedBox(
      width: 36,
      height: 36,
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final int seedPoints;

  const _TopHeader({required this.seedPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B21D27),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_florist, size: 30, color: Color(0xFFB21D27)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Grow Watermelon',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFB21D27),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: Color(0xFF705900),
                ),
                const SizedBox(width: 4),
                Text(
                  '$seedPoints 西瓜子',
                  style: const TextStyle(
                    color: Color(0xFF273034),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 成熟期兑换横幅 ───────────────────────────────────────────────────────────
class _HarvestBanner extends ConsumerWidget {
  final PetModel pet;
  const _HarvestBanner({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showHarvestDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B6B1B), Color(0xFF3DAA3D)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3A1B6B1B),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🍉', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '西瓜成熟啦！',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '第 ${pet.harvestCount + 1} 季 · 点击兑换真实西瓜 🎉',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _showHarvestDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🍉 兑换真实西瓜'),
        content: Text(
          '这是你的第 ${pet.harvestCount + 1} 次丰收！\n\n'
          '工作人员会联系你安排发货，兑换后西瓜将重新开始生长。\n\n'
          '确认兑换吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B6B1B)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认兑换'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(myPetProvider.notifier).harvestPet();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 兑换成功！工作人员将尽快联系你'),
            backgroundColor: Color(0xFF1B6B1B),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('兑换失败：$e')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String valueText;
  final String suffixText;
  final double progress;
  final bool segmented;
  final int segments;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.valueText,
    required this.suffixText,
    required this.progress,
    this.segmented = false,
    this.segments = 5,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B21D27),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF545D62),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: segmented ? accentColor : const Color(0xFF273034),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  suffixText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6F787D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!segmented)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 8,
                backgroundColor: const Color(0xFFD1DFE7),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          if (segmented)
            Row(
              children: List.generate(segments, (index) {
                final threshold = (index + 1) / segments;
                final active = clamped >= threshold;
                return Expanded(
                  child: Container(
                    height: 8,
                    margin:
                        EdgeInsets.only(right: index == segments - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: active ? accentColor : const Color(0xFFD1DFE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _TodayGrowthCard extends StatelessWidget {
  final int todayPoints;

  const _TodayGrowthCard({required this.todayPoints});

  @override
  Widget build(BuildContext context) {
    // 每日 80 分为满状态
    final progress = (todayPoints / 80).clamp(0.0, 1.0);
    final statusText = todayPoints >= 80
        ? '西瓜今天超开心 😄'
        : todayPoints >= 60
            ? '西瓜今天很满足 😊'
            : todayPoints >= 30
                ? '继续努力，西瓜在等你！ 😕'
                : todayPoints > 0
                    ? '西瓜有点渴了，快去完成任务！ 😢'
                    : '完成任务让西瓜长大吧 🌱';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E7D32),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🍉', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '$todayPoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  '今日积分',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackground;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickInfoCard({
    required this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackground,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            iconWidget ?? Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetLoadingCard extends StatelessWidget {
  const _PetLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: double.infinity,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '加载失败: $message',
          style: const TextStyle(color: Color(0xFFB02500)),
        ),
      ),
    );
  }
}

class _NoPetCard extends StatelessWidget {
  const _NoPetCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text(
              '还没有西瓜，先种下一颗种子吧！',
              style: TextStyle(fontSize: 16, color: Color(0xFF545D62)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/onboarding/circle'),
              icon: const Icon(Icons.eco),
              label: const Text('开始养西瓜'),
            ),
          ],
        ),
      ),
    );
  }
}
