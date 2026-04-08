import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/task_log_model.dart';
import '../../../models/user_task_model.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/user_task_provider.dart';
import '../../../repositories/task_repository.dart';
import '../widgets/task_card_widget.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  /// userTaskId → 正在处理中（防止重复触发）
  final Set<String> _processingTasks = {};

  @override
  Widget build(BuildContext context) {
    final todayPoints = ref.watch(todayPointsProvider);
    final logs =
        ref.watch(todayTaskLogsProvider).valueOrNull ?? const <TaskLogModel>[];
    final userTasksAsync = ref.watch(userTasksProvider);

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
                '已浇 $todayPoints 💧',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '添加任务',
            onPressed: () => _showAddTaskSheet(context),
          ),
        ],
      ),
      body: userTasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (userTasks) {
          if (userTasks.isEmpty) {
            return _EmptyTasksHint(onAdd: () => _showAddTaskSheet(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: userTasks.length,
            itemBuilder: (context, index) {
              final userTask = userTasks[index];
              final isCompleted = logs.any(
                (e) => e.taskType.name == userTask.template.key && e.completed,
              );
              return TaskCardWidget(
                userTask: userTask,
                isCompleted: isCompleted,
                isProcessing: _processingTasks.contains(userTask.id),
                onUploadEvidence: (evidenceType) =>
                    _uploadEvidence(userTask, evidenceType),
                onDelete: () => _confirmDelete(context, userTask),
              );
            },
          );
        },
      ),
    );
  }

  // ── 添加任务弹窗 ─────────────────────────────────────────────

  Future<void> _showAddTaskSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddTaskSheet(),
    );
  }

  // ── 删除确认 ─────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, UserTaskModel userTask) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${userTask.template.name}」'),
        content: const Text('删除后今日任务列表中将不再显示此任务，历史记录仍保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(manageUserTaskProvider.notifier).removeTask(userTask.id);
  }

  // ── 上传证据 ─────────────────────────────────────────────────

  Future<void> _uploadEvidence(
      UserTaskModel userTask, String evidenceType) async {
    if (_processingTasks.contains(userTask.id)) return;
    setState(() => _processingTasks.add(userTask.id));

    try {
      XFile? evidenceXFile;
      if (evidenceType == 'image') {
        evidenceXFile = await _captureImage();
      } else if (evidenceType == 'video') {
        evidenceXFile = await _recordVideo();
      } else {
        evidenceXFile = await _recordAudio(userTask.template.name);
      }
      if (evidenceXFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未选择或未采集到证据'),
              backgroundColor: Color(0xFF6F787D),
            ),
          );
        }
        return;
      }

      final tpl = userTask.template;
      final created = await ref.read(submitTaskProvider.notifier).submitByTemplate(
            templateKey: tpl.key,
            templateName: tpl.name,
            durationMinutes: tpl.isTimeBased ? 15 : 0,
          );

      // 上传媒体证据文件（用 readAsBytes 兼容 Web）
      final bytes = await evidenceXFile.readAsBytes();
      final filename = evidenceXFile.name.isNotEmpty
          ? evidenceXFile.name
          : 'evidence_${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(taskRepositoryProvider).uploadEvidence(created.id, bytes, filename);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tpl.name} 证据已提交，完成 +${tpl.pointsPer15Min} 分'),
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
      if (mounted) setState(() => _processingTasks.remove(userTask.id));
    }
  }

  Future<XFile?> _captureImage() async {
    final source = await _pickMediaSource(label: '拍照');
    if (source == null) return null;

    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } on PlatformException catch (e) {
      _showInfo('打开图片选择失败：${e.message ?? e.code}');
      return null;
    }
    if (image == null) return null;
    if (source == ImageSource.gallery && !await _isFromToday(image)) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('照片不是今天的'),
            content: const Text('请选择今天拍摄的照片作为任务证据。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
      return null;
    }
    return image;
  }

  Future<XFile?> _recordVideo() async {
    if (kIsWeb) {
      _showInfo('网页版不支持视频录制，请使用 App');
      return null;
    }
    final source = await _pickMediaSource(label: '录像');
    if (source == null) return null;

    final picker = ImagePicker();
    XFile? video;
    try {
      video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );
    } on PlatformException catch (e) {
      _showInfo('打开视频选择失败：${e.message ?? e.code}');
      return null;
    }
    if (video == null) return null;
    if (source == ImageSource.gallery && !await _isFromToday(video)) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('视频不是今天的'),
            content: const Text('请选择今天录制的视频作为任务证据。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
      return null;
    }
    return video;
  }

  /// 用 AlertDialog 选择来源（避免 ModalBottomSheet 与原生 picker 的 iOS 视图控制器冲突）
  Future<ImageSource?> _pickMediaSource({required String label}) {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('选择$label方式'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Row(
              children: [
                Icon(Icons.camera_alt_outlined),
                SizedBox(width: 12),
                Text('现在拍摄', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Row(
              children: [
                Icon(Icons.photo_library_outlined),
                SizedBox(width: 12),
                Text('从相册选取（仅限今日）', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF6F787D),
      ),
    );
  }

  /// 校验文件修改时间是否为今天（debug / web 模式跳过）
  Future<bool> _isFromToday(XFile xFile) async {
    if (kDebugMode || kIsWeb) return true;
    try {
      final modified = await xFile.lastModified();
      final now = DateTime.now();
      return modified.year == now.year &&
          modified.month == now.month &&
          modified.day == now.day;
    } catch (_) {
      return true;
    }
  }

  Future<XFile?> _recordAudio(String taskName) async {
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
                final String filePath;
                if (kIsWeb) {
                  filePath = '';
                } else {
                  final dir = await getTemporaryDirectory();
                  filePath =
                      '${dir.path}/task_${DateTime.now().millisecondsSinceEpoch}.m4a';
                }
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
                    '为「$taskName」录音',
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
    if (outputPath == null || outputPath!.isEmpty) return null;
    return XFile(outputPath!);
  }
}

// ── 空状态提示 ────────────────────────────────────────────────

class _EmptyTasksHint extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTasksHint({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 52)),
          const Gap(16),
          const Text(
            '还没有任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(6),
          const Text(
            '点击右上角 + 添加今日要完成的任务',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Gap(24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加任务'),
          ),
        ],
      ),
    );
  }
}

// ── 添加任务底部弹窗 ──────────────────────────────────────────

class _AddTaskSheet extends ConsumerWidget {
  const _AddTaskSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(taskTemplatesProvider);
    final userTasksAsync = ref.watch(userTasksProvider);
    final manageState = ref.watch(manageUserTaskProvider);

    final addedTemplateIds =
        userTasksAsync.valueOrNull?.map((t) => t.template.id).toSet() ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    '选择要添加的任务',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败：$e')),
                data: (templates) => ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final tpl = templates[index];
                    final alreadyAdded = addedTemplateIds.contains(tpl.id);
                    final color = Color(
                      int.parse(tpl.colorHex.replaceAll('#', '0xFF')),
                    );
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(tpl.emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      title: Text(
                        tpl.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        tpl.isTimeBased
                            ? '每15分钟 +${tpl.pointsPer15Min}分'
                            : '完成即得 +${tpl.pointsPer15Min}分',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: alreadyAdded
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary)
                          : FilledButton(
                              onPressed: manageState.isLoading
                                  ? null
                                  : () async {
                                      await ref
                                          .read(manageUserTaskProvider.notifier)
                                          .addTask(tpl.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('已添加「${tpl.name}」'),
                                            backgroundColor:
                                                const Color(0xFF006B1B),
                                          ),
                                        );
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: color.withValues(alpha: 0.85),
                                minimumSize: const Size(60, 34),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('添加',
                                  style: TextStyle(fontSize: 13)),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
