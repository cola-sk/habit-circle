import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 循环播放 IP 形象 MP4 动画。
/// [assetPath] 为 assets 路径，如 'assets/animations/ip_zhongzi.mp4'。
/// [fallbackEmoji] 在视频初始化完成前或 assetPath 为 null 时显示的 emoji 占位。
class IpVideoWidget extends StatefulWidget {
  final String assetPath;
  final double size;
  final String? fallbackEmoji;

  const IpVideoWidget({
    super.key,
    required this.assetPath,
    this.size = 160,
    this.fallbackEmoji,
  });

  @override
  State<IpVideoWidget> createState() => _IpVideoWidgetState();
}

class _IpVideoWidgetState extends State<IpVideoWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initController(widget.assetPath);
  }

  @override
  void didUpdateWidget(IpVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _controller.dispose();
      _initialized = false;
      _error = null;
      _initController(widget.assetPath);
    }
  }

  void _initController(String assetPath) {
    _controller = VideoPlayerController.asset(assetPath)
      ..setLooping(true)
      ..setVolume(0);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        _controller.play();
      }
    }).catchError((e) {
      debugPrint('[IpVideoWidget] 视频初始化失败 ($assetPath): $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 有错误或未初始化时，降级显示 emoji
    if (_error != null || !_initialized) {
      return Text(
        widget.fallbackEmoji ?? '🌱',
        style: const TextStyle(fontSize: 64),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: VideoPlayer(_controller),
    );
  }
}
