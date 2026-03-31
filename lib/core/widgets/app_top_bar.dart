import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';

/// 通用顶部栏
///
/// 使用方式：在 Scaffold 中替代 AppBar：
/// ```dart
/// appBar: AppTopBar(title: '西瓜广场')
/// ```
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final pet = ref.watch(myPetProvider).valueOrNull;

    final initial = (user?.childName.isNotEmpty == true)
        ? user!.childName[0]
        : '?';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x1A4CAF50), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // 头像
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 标题
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: 1,
                ),
              ),

              const Spacer(),

              // 积分芯片
              if (pet != null) _PointsChip(points: pet.totalPoints),

              // 额外 actions
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// 西瓜子积分芯片，可单独使用
class _PointsChip extends StatelessWidget {
  final int points;

  const _PointsChip({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1B5E20),
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('�', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$points 积分',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 通用积分数量展示（用于 HomeScreen 等需要展示积分的地方）
class PointsChipWidget extends StatelessWidget {
  final int points;

  const PointsChipWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) => _PointsChip(points: points);
}
