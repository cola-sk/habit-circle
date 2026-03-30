import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/task_types.dart';

/// 任务卡片（证据上传模式）
class TaskCardWidget extends StatelessWidget {
  final TaskType taskType;
  final bool isCompleted;
  final bool isProcessing;
  final VoidCallback onUploadEvidence;

  const TaskCardWidget({
    super.key,
    required this.taskType,
    required this.isCompleted,
    required this.isProcessing,
    required this.onUploadEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(taskType.colorHex.replaceAll('#', '0xFF')),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isCompleted ? const Color(0x55006B1B) : const Color(0x1FA5AEB4),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(taskType.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const Gap(14),
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
                  '完成方式：${taskType.evidenceType.displayName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const _CompletedChip()
          else
            _UploadButton(
              color: color,
              label: taskType.submitActionLabel,
              icon: taskType.evidenceType == TaskEvidenceType.image
                  ? Icons.camera_alt
                  : Icons.mic,
              isLoading: isProcessing,
              onTap: onUploadEvidence,
            ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _UploadButton({
    required this.color,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(112, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(
        isLoading ? '处理中' : label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CompletedChip extends StatelessWidget {
  const _CompletedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1A006B1B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Color(0xFF006B1B)),
          SizedBox(width: 4),
          Text(
            '已完成',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF006B1B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
