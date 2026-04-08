import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_task_model.dart';

/// 任务卡片（基于 UserTaskModel，支持多证据类型 + 删除）
class TaskCardWidget extends StatelessWidget {
  final UserTaskModel userTask;
  final bool isCompleted;
  final bool isProcessing;

  /// 触发上传证据，参数为证据类型 "image" | "audio"
  final ValueChanged<String> onUploadEvidence;
  final VoidCallback onDelete;

  const TaskCardWidget({
    super.key,
    required this.userTask,
    required this.isCompleted,
    required this.isProcessing,
    required this.onUploadEvidence,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tpl = userTask.template;
    final color = Color(int.parse(tpl.colorHex.replaceAll('#', '0xFF')));

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 上方：图标 + 任务名称 + 积分 + 已完成/删除
          Row(
            children: [
              // 图标
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(tpl.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const Gap(14),
              // 任务名称 + 积分说明
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tpl.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      tpl.isTimeBased
                          ? '每15分钟 +${tpl.pointsPer15Min}分'
                          : '完成即得 +${tpl.pointsPer15Min}分',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              if (isCompleted)
                const _CompletedChip()
              else
                // 删除按钮单独放右上角
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0x0FFF3B30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
            ],
          ),
          // 下方：证据按钮行（仅未完成时显示）
          if (!isCompleted) ...[
            const Gap(10),
            _EvidenceBtnRow(
              template: tpl,
              color: color,
              isProcessing: isProcessing,
              onUploadEvidence: onUploadEvidence,
            ),
          ],
        ],
      ),
    );
  }
}

// ── 证据按钮行（横向铺满） ────────────────────────────────────

class _EvidenceBtnRow extends StatelessWidget {
  final TaskTemplateModel template;
  final Color color;
  final bool isProcessing;
  final ValueChanged<String> onUploadEvidence;

  const _EvidenceBtnRow({
    required this.template,
    required this.color,
    required this.isProcessing,
    required this.onUploadEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (template.supportsImage) {
      buttons.add(_EvidenceBtn(
        color: color,
        icon: Icons.camera_alt,
        label: '拍照',
        isLoading: isProcessing,
        onTap: () => onUploadEvidence('image'),
      ));
    }
    if (template.supportsAudio) {
      buttons.add(_EvidenceBtn(
        color: color,
        icon: Icons.mic,
        label: '录音',
        isLoading: isProcessing,
        onTap: () => onUploadEvidence('audio'),
      ));
    }
    if (template.supportsVideo) {
      buttons.add(_EvidenceBtn(
        color: color,
        icon: Icons.videocam,
        label: '录像',
        isLoading: isProcessing,
        onTap: () => onUploadEvidence('video'),
      ));
    }

    return Row(
      children: buttons
          .expand((btn) => [btn, const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }
}

class _EvidenceBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _EvidenceBtn({
    required this.color,
    required this.icon,
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 14),
      label: Text(
        isLoading ? '…' : label,
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
