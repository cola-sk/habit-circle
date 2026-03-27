import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/task_types.dart';
import '../../../providers/timer_provider.dart';
import '../../../providers/task_provider.dart';

/// 任务卡片
class TaskCardWidget extends ConsumerWidget {
  final TaskType taskType;
  final bool isTimerActive;
  final VoidCallback onStart;

  const TaskCardWidget({
    super.key,
    required this.taskType,
    required this.isTimerActive,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(
      int.parse(taskType.colorHex.replaceAll('#', '0xFF')),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isTimerActive
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isTimerActive ? () => _showActiveTimer(context) : onStart,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(taskType.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const Gap(14),

                // 任务信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskType.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        taskType.isTimeBased
                            ? '每15分钟 +${taskType.pointsPer15Min}分'
                            : '完成即得 +${taskType.pointsPer15Min}分',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 按钮区域
                if (isTimerActive)
                  _TimingChip()
                else
                  _StartButton(color: color, onTap: onStart),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActiveTimer(BuildContext context) {
    // 恢复计时器底部弹窗（暂时用 snackbar 提示）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('计时进行中，向下滚动查看')),
    );
  }
}

class _StartButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _StartButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '开始',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: AppColors.primary),
          Gap(4),
          Text(
            '计时中',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 完成确认对话框（非计时任务）
class TaskCompletionDialog extends ConsumerWidget {
  final TaskType taskType;

  const TaskCompletionDialog({super.key, required this.taskType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('完成 ${taskType.displayName}？'),
      content: Text(
        '确认完成后将获得 +${taskType.pointsPer15Min} 分！',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await ref.read(submitTaskProvider.notifier).submit(
                  taskType: taskType,
                  durationMinutes: 0,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('完成！+${taskType.pointsPer15Min} 分 🎉'),
                  backgroundColor: AppColors.petHappy,
                ),
              );
            }
          },
          child: const Text('完成！'),
        ),
      ],
    );
  }
}
