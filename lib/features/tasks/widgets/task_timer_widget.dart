import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/task_types.dart';
import '../../../providers/timer_provider.dart';
import '../../../providers/task_provider.dart';

/// 计时器底部弹窗
class TaskTimerWidget extends ConsumerWidget {
  final TaskType taskType;

  const TaskTimerWidget({super.key, required this.taskType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(20),

          Text(
            taskType.emoji,
            style: const TextStyle(fontSize: 48),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1500.ms,
            color: AppColors.accent,
          ),
          const Gap(8),

          Text(
            taskType.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(24),

          // 计时器显示
          Text(
            timerState.formattedTime,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Gap(8),

          Text(
            '已计时 ${timerState.elapsedMinutes} 分钟  '
            '+${PointsCalculator.calculate(taskType, timerState.elapsedMinutes)} 分',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(32),

          // 控制按钮
          Row(
            children: [
              // 暂停/继续
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (timerState.isRunning) {
                      ref.read(timerProvider.notifier).pause();
                    } else {
                      ref.read(timerProvider.notifier).resume();
                    }
                  },
                  icon: Icon(
                    timerState.isRunning ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(timerState.isRunning ? '暂停' : '继续'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const Gap(12),

              // 完成
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final minutes = ref.read(timerProvider.notifier).stop();
                    Navigator.of(context).pop();
                    if (minutes < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('至少需要 1 分钟才能记录哦！')),
                      );
                      return;
                    }
                    await ref.read(submitTaskProvider.notifier).submit(
                          taskType: taskType,
                          durationMinutes: minutes,
                        );
                    final points =
                        PointsCalculator.calculate(taskType, minutes);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('太棒了！$minutes 分钟 → +$points 分 🎉'),
                          backgroundColor: AppColors.petHappy,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('完成任务'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
