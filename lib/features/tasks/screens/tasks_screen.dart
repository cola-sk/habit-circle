import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/task_types.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/timer_provider.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/task_timer_widget.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  static const _taskTypes = TaskType.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final todayPoints = ref.watch(todayPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('今日任务'),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '已得 $todayPoints 分',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 进行中的计时器横幅
          if (timerState.isRunning || timerState.elapsedSeconds > 0)
            _ActiveTimerBanner(timerState: timerState),

          // 任务列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: _taskTypes.length,
              itemBuilder: (context, index) {
                final taskType = _taskTypes[index];
                return TaskCardWidget(
                  taskType: taskType,
                  isTimerActive: timerState.isRunning &&
                      timerState.activeTaskId == taskType.name,
                  onStart: () => _startTask(context, ref, taskType),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startTask(BuildContext context, WidgetRef ref, TaskType taskType) {
    final timerState = ref.read(timerProvider);
    if (timerState.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先完成当前任务再开始新的！')),
      );
      return;
    }

    // 作业类型：直接显示完成对话框
    if (!taskType.isTimeBased) {
      showDialog(
        context: context,
        builder: (_) => TaskCompletionDialog(taskType: taskType),
      );
      return;
    }

    // 其他：启动计时器
    ref.read(timerProvider.notifier).start(taskType.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskTimerWidget(taskType: taskType),
    );
  }
}

class _ActiveTimerBanner extends StatelessWidget {
  final TimerState timerState;

  const _ActiveTimerBanner({required this.timerState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 20),
          const Gap(8),
          Text(
            '计时中 ${timerState.formattedTime}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Text('点击任务卡片查看',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
