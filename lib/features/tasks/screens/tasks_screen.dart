import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/task_types.dart';
import '../../../models/task_log_model.dart';
import '../../../providers/task_provider.dart';
import '../widgets/task_card_widget.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  static const _taskTypes = TaskType.values;
  final Set<TaskType> _processingTasks = <TaskType>{};

  @override
  Widget build(BuildContext context) {
    final todayPoints = ref.watch(todayPointsProvider);
    final logs =
        ref.watch(todayTaskLogsProvider).valueOrNull ?? const <TaskLogModel>[];

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
                color: AppColors.primary.withValues(alpha: 0.1),
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
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _taskTypes.length,
        itemBuilder: (context, index) {
          final taskType = _taskTypes[index];
          final isCompleted = logs.any(
            (e) => e.taskType == taskType && e.completed,
          );

          return TaskCardWidget(
            taskType: taskType,
            isCompleted: isCompleted,
            isProcessing: _processingTasks.contains(taskType),
            onUploadEvidence: () => _uploadEvidence(taskType),
          );
        },
      ),
    );
  }

  Future<void> _uploadEvidence(TaskType taskType) async {
    if (_processingTasks.contains(taskType)) return;
    setState(() => _processingTasks.add(taskType));

    try {
      String? evidencePath;
      if (taskType.evidenceType == TaskEvidenceType.image) {
        evidencePath = await _captureImage();
      } else {
        evidencePath = await _recordAudio(taskType);
      }

      if (evidencePath == null || evidencePath.isEmpty) return;

      await ref.read(submitTaskProvider.notifier).submit(
            taskType: taskType,
            durationMinutes: taskType.evidenceSubmitMinutes,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${taskType.displayName} 证据已提交，任务完成 +${taskType.pointsPer15Min} 分',
          ),
          backgroundColor: const Color(0xFF006B1B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传失败：$e'),
          backgroundColor: const Color(0xFFB02500),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingTasks.remove(taskType));
      }
    }
  }

  Future<String?> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    return image?.path;
  }

  Future<String?> _recordAudio(TaskType taskType) async {
    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('没有麦克风权限，请在系统设置中开启'),
            backgroundColor: Color(0xFFB02500),
          ),
        );
      }
      await recorder.dispose();
      return null;
    }

    String? outputPath;

    if (!mounted) {
      await recorder.dispose();
      return null;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var isRecording = false;
        var isBusy = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> startRecording() async {
              if (isBusy || isRecording) return;
              setState(() => isBusy = true);
              try {
                final dir = await getTemporaryDirectory();
                final filePath =
                    '${dir.path}/task_${taskType.name}_${DateTime.now().millisecondsSinceEpoch}.m4a';
                await recorder.start(
                  const RecordConfig(
                    encoder: AudioEncoder.aacLc,
                    bitRate: 128000,
                    sampleRate: 44100,
                  ),
                  path: filePath,
                );
                outputPath = filePath;
                isRecording = true;
              } finally {
                setState(() => isBusy = false);
              }
            }

            Future<void> stopAndUse() async {
              if (isBusy || !isRecording) return;
              setState(() => isBusy = true);
              try {
                final path = await recorder.stop();
                if (path != null && path.isNotEmpty) {
                  outputPath = path;
                }
                if (context.mounted) Navigator.of(context).pop();
              } finally {
                setState(() => isBusy = false);
              }
            }

            Future<void> cancelRecording() async {
              if (isBusy) return;
              if (isRecording) {
                await recorder.stop();
              }
              outputPath = null;
              if (context.mounted) Navigator.of(context).pop();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '为「${taskType.displayName}」录音',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    isRecording ? '录音中，请家长点击“停止并上传”' : '点击“开始录音”后进行任务口述/演奏采集',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isRecording ? null : startRecording,
                          icon: const Icon(Icons.mic),
                          label: const Text('开始录音'),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isRecording ? stopAndUse : null,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('停止并上传'),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  TextButton(
                    onPressed: cancelRecording,
                    child: const Text('取消'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    await recorder.dispose();
    return outputPath;
  }
}
