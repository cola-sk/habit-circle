import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 礼花粒子覆盖层，调用 ConfettiOverlay.show(context) 触发
class ConfettiOverlay {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiWidget(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ConfettiWidget extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiWidget({required this.onDone});

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  static const _count = 60;
  static const _colors = [
    Color(0xFFFF4D4D),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF69B4),
    Color(0xFFFF8C00),
  ];

  late final List<_Particle> _particles;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(_count, (_) => _Particle(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Stack(
            children: _particles.map((p) {
              final t = _controller.value;
              final x = p.startX * size.width +
                  p.vx * t * size.width * 0.5;
              final y = p.startY * size.height +
                  p.vy * t * size.height +
                  0.5 * 9.8 * t * t * size.height * 0.25;
              final opacity = (1.0 - (t - 0.6).clamp(0.0, 1.0) / 0.4);
              return Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: p.spin * t * math.pi * 4,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Container(
                      width: p.size,
                      height: p.size * (p.isCircle ? 1 : 0.5),
                      decoration: BoxDecoration(
                        color: _colors[p.colorIndex],
                        shape: p.isCircle
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: p.isCircle
                            ? null
                            : BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double spin;
  final double size;
  final int colorIndex;
  final bool isCircle;

  _Particle(math.Random rng)
      : startX = rng.nextDouble(),
        startY = -0.05 - rng.nextDouble() * 0.15,
        vx = (rng.nextDouble() - 0.5) * 0.6,
        vy = 0.3 + rng.nextDouble() * 0.5,
        spin = (rng.nextDouble() - 0.5) * 2,
        size = 6 + rng.nextDouble() * 10,
        colorIndex = rng.nextInt(6),
        isCircle = rng.nextBool();
}

/// 加油消息弹窗，显示送加油的人名 + 礼花
class CheerMessageDialog extends StatelessWidget {
  final List<String> cheerers;

  const CheerMessageDialog({super.key, required this.cheerers});

  static Future<void> showIfNeeded(
    BuildContext context,
    List<String> cheerers,
  ) async {
    if (cheerers.isEmpty) return;
    ConfettiOverlay.show(context);
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CheerMessageDialog(cheerers: cheerers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final names = _formatNames(cheerers);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52))
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.1, 1.1),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .scale(
                  end: const Offset(1.0, 1.0),
                  duration: 150.ms,
                ),
            const SizedBox(height: 16),
            const Text(
              '收到加油啦！',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB21D27),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$names 给你加油了，今天一定要记得好好学习哦 💪',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB21D27),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '我知道了，出发！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNames(List<String> names) {
    if (names.length == 1) return names[0];
    if (names.length <= 3) return names.join('、');
    return '${names.take(3).join('、')} 等 ${names.length} 位小朋友';
  }
}
