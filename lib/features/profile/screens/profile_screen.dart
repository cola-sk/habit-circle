import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/pet_species.dart';
import '../../../core/constants/task_types.dart';
import '../../../core/widgets/ip_video_widget.dart';
import '../../../models/pet_model.dart';
import '../../../models/task_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../repositories/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final currentUser = ref.watch(currentUserProvider);
    final pet = ref.watch(myPetProvider).valueOrNull;
    final logs =
        ref.watch(todayTaskLogsProvider).valueOrNull ?? const <TaskLogModel>[];
    final weekLogs =
        ref.watch(thisWeekTaskLogsProvider).valueOrNull ?? const <TaskLogModel>[];
    final recentPoints =
        ref.watch(recentFiveDaysPointsProvider).valueOrNull ?? const <String, int>{};
    final todayPoints = ref.watch(todayPointsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF8FE),
      body: SafeArea(
        child: currentUser.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('错误：$e')),
          data: (user) {
            if (user == null) return const SizedBox.shrink();

            final completedCount = weekLogs.where((e) => e.completed).length;
            const weeklyTarget = 20;
            final weeklyProgress = weeklyTarget == 0
                ? 0.0
                : (completedCount / weeklyTarget).clamp(0.0, 1.0);
            final ripenessPercent = _ripenessPercent(pet);
            final weeklyBars = _buildWeeklyBars(recentPoints);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(seedPoints: pet?.totalPoints ?? 0),
                  const SizedBox(height: 14),
                  _HeroCard(
                    childName: user.childName,
                    todayPoints: todayPoints,
                    ripenessPercent: ripenessPercent,
                    growthStage: pet?.growthStage ?? 'seed',
                    growthStageName: pet?.growthStageDisplayName ?? '种子期',
                    hasCompletedToday: logs.any((e) => e.completed),
                  ),
                  const SizedBox(height: 10),
                  _GrowthAtlasEntryCard(
                    stageName: pet?.growthStageDisplayName ?? '种子期',
                    onTap: () => context.push('/profile/growth'),
                  ),
                  const SizedBox(height: 14),
                  _WeeklyGoalCard(
                    progress: weeklyProgress,
                    completedCount: completedCount,
                    weeklyTarget: weeklyTarget,
                    circleJoinedText: user.circleId == null ? '未加入圈子' : '已加入圈子',
                    joinDateText: _formatDate(user.createdAt),
                  ),
                  const SizedBox(height: 14),
                  _WeeklyGrowthCard(bars: weeklyBars),
                  const SizedBox(height: 14),
                  const _BadgeWallCard(),
                  const SizedBox(height: 14),
                  _TaskSection(
                    logs: logs,
                    onGoTasks: () => context.go('/tasks'),
                  ),
                  const SizedBox(height: 18),
                  _LogoutButton(
                    onPressed: () => _signOut(context, ref),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  static int _ripenessPercent(PetModel? pet) {
    if (pet == null || pet.totalPoints <= 0) return 0;
    final ripeThreshold = PetLevelThresholds.growthStageThresholds.last;
    final ratio = (pet.totalPoints / ripeThreshold).clamp(0.0, 1.0);
    return (ratio * 100).round();
  }

  static List<_DayBarData> _buildWeeklyBars(Map<String, int> pointsByDate) {
    final today = DateTime.now();
    final days = List.generate(5, (i) {
      final d = today.subtract(Duration(days: 4 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final maxPoints = math.max(
        1,
        pointsByDate.values.isEmpty
            ? 1
            : pointsByDate.values.fold(0, math.max));
    return days.map((day) {
      final dateKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final points = pointsByDate[dateKey] ?? 0;
      final ratio = (points / maxPoints).clamp(0.0, 1.0);
      final isToday = _isSameDay(day, today);
      return _DayBarData(
        label: isToday ? '今天' : _weekdayLabel(day.weekday),
        points: points,
        ratio: ratio,
        isToday: isToday,
      );
    }).toList();
  }

  static String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '周一';
      case DateTime.tuesday:
        return '周二';
      case DateTime.wednesday:
        return '周三';
      case DateTime.thursday:
        return '周四';
      case DateTime.friday:
        return '周五';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
      default:
        return '今日';
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text(
              '退出',
              style: TextStyle(color: Color(0xFFB02500)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    ref.read(authStateNotifierProvider).logout();
    if (context.mounted) {
      context.go('/onboarding/welcome');
    }
  }
}

class _TopBar extends StatelessWidget {
  final int seedPoints;

  const _TopBar({required this.seedPoints});

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
              '养西瓜',
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
              color: Colors.white.withValues(alpha: 0.9),
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
                  '$seedPoints Seeds',
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
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String childName;
  final int todayPoints;
  final int ripenessPercent;
  final String growthStage;
  final String growthStageName;
  final bool hasCompletedToday;

  const _HeroCard({
    required this.childName,
    required this.todayPoints,
    required this.ripenessPercent,
    required this.growthStage,
    required this.growthStageName,
    required this.hasCompletedToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB21D27), Color(0xFFFF7671)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29B21D27),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '亲爱的家长，你好！',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$childName 今天表现很好，果园正在成长。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroMetricChip(
                  title: '当前种子',
                  value: '$todayPoints',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroMetricChip(
                  title: '西瓜熟度',
                  value: '$ripenessPercent%',
                  subtitle: growthStageName,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildIpDisplay(growthStage, hasCompletedToday),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIpDisplay(String growthStage, bool hasCompletedToday) {
    final stage = WatermelonGrowthStageExtension.fromName(growthStage);
    final videoAsset = stage.ipVideoAsset(hasCompletedToday: hasCompletedToday);
    if (videoAsset != null) {
      return IpVideoWidget(
        assetPath: videoAsset,
        size: 76,
        fallbackEmoji: '🌱',
      );
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        _growthImageAsset(growthStage),
        fit: BoxFit.contain,
      ),
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

class _HeroMetricChip extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;

  const _HeroMetricChip({
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrowthAtlasEntryCard extends StatelessWidget {
  final String stageName;
  final VoidCallback onTap;

  const _GrowthAtlasEntryCard({
    required this.stageName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AA5AEB4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: Color(0xFFB21D27)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '成长图鉴 · 当前$stageName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF273034),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text(
              '查看全部阶段',
              style: TextStyle(
                color: Color(0xFFB21D27),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  final double progress;
  final int completedCount;
  final int weeklyTarget;
  final String circleJoinedText;
  final String joinDateText;

  const _WeeklyGoalCard({
    required this.progress,
    required this.completedCount,
    required this.weeklyTarget,
    required this.circleJoinedText,
    required this.joinDateText,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1AA5AEB4)),
            ),
            child: Column(
              children: [
                const Text(
                  '本周目标完成度',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF545D62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 132,
                        height: 132,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 11,
                          color: Color(0xFFD8E4EC),
                        ),
                      ),
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 11,
                          color: const Color(0xFF006B1B),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Color(0xFF273034),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            '继续努力',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF006B1B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '已完成 $completedCount/$weeklyTarget 项任务',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF545D62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1E7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.forest,
                  size: 30,
                  color: Color(0xFF006B1B),
                ),
                const SizedBox(height: 8),
                Text(
                  circleJoinedText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF005E17),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '加入时间：$joinDateText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF005E17),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '家长可在任务页管理任务模板',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00691A),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyGrowthCard extends StatelessWidget {
  final List<_DayBarData> bars;

  const _WeeklyGrowthCard({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '每周成长趋势',
                style: TextStyle(
                  fontSize: 19,
                  color: Color(0xFF273034),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '最近5天',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF545D62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 166,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (bar) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 24,
                                  height: 120 * (0.2 + 0.8 * bar.ratio),
                                  decoration: BoxDecoration(
                                    color: bar.isToday
                                        ? const Color(0xFFB21D27)
                                        : const Color(0x66FF7671),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              bar.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: bar.isToday
                                    ? const Color(0xFFB21D27)
                                    : const Color(0xFF545D62),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${bar.points}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6F787D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeWallCard extends StatelessWidget {
  const _BadgeWallCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1AA5AEB4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '勋章墙',
            style: TextStyle(
              fontSize: 19,
              color: Color(0xFF273034),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BadgeTile(
                  icon: Icons.workspace_premium,
                  label: '早起之星',
                  background: Color(0xFFFFF2D4),
                  iconColor: Color(0xFF705900),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _BadgeTile(
                  icon: Icons.park,
                  label: '小小农夫',
                  background: Color(0xFFD1FFC8),
                  iconColor: Color(0xFF006B1B),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _BadgeTile(
                  icon: Icons.auto_awesome,
                  label: '创造大师',
                  background: Color(0x22FF7671),
                  iconColor: Color(0xFFB21D27),
                  locked: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color iconColor;
  final bool locked;

  const _BadgeTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.iconColor,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Opacity(
        opacity: locked ? 0.45 : 1,
        child: Column(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF273034),
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final List<TaskLogModel> logs;
  final VoidCallback onGoTasks;

  const _TaskSection({
    required this.logs,
    required this.onGoTasks,
  });

  @override
  Widget build(BuildContext context) {
    final sortedLogs = [...logs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1AA5AEB4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '当前活动任务',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFF273034),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006B1B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(112, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: onGoTasks,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  '新建任务',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sortedLogs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: const Text(
                '今天还没有任务记录',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6F787D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...sortedLogs.take(3).map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskTile(
                      log: log,
                      onTap: onGoTasks,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskLogModel log;
  final VoidCallback onTap;

  const _TaskTile({
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Color(
      int.parse(log.taskType.colorHex.replaceAll('#', '0xFF')),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FA5AEB4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _taskIcon(log.taskType),
              size: 26,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.taskName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF273034),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF6F787D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${log.durationMinutes} 分钟',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF545D62),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.park,
                          size: 14,
                          color: Color(0xFFB21D27),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '+${log.points} 种子',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB21D27),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit, color: Color(0xFF545D62)),
            tooltip: '编辑',
          ),
          IconButton(
            onPressed: onTap,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFB02500)),
            tooltip: '删除',
          ),
        ],
      ),
    );
  }

  static IconData _taskIcon(TaskType type) {
    switch (type) {
      case TaskType.reading:
        return Icons.menu_book;
      case TaskType.piano:
        return Icons.piano;
      case TaskType.english:
        return Icons.translate;
      case TaskType.preview:
        return Icons.chrome_reader_mode;
      case TaskType.homework:
        return Icons.edit_note;
      case TaskType.exercise:
        return Icons.fitness_center;
      case TaskType.custom:
        return Icons.auto_awesome;
    }
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: const Color(0x1AB02500),
        foregroundColor: const Color(0xFFB02500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      child: const Text(
        '退出登录',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DayBarData {
  final String label;
  final int points;
  final double ratio;
  final bool isToday;

  const _DayBarData({
    required this.label,
    required this.points,
    required this.ratio,
    required this.isToday,
  });
}
