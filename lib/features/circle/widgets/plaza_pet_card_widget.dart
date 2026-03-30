import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pet_species.dart';
import '../../../models/pet_model.dart';

/// 西瓜广场宠物卡片
///
/// isMe=true 时显示成长进度条，false 时显示"加油"按钮
class PlazaPetCard extends StatelessWidget {
  final PetModel pet;
  final bool isMe;

  /// 显示在卡片左上角的头像首字
  final String ownerInitial;

  /// 点击加油回调（isMe=false 时有效）
  final VoidCallback? onCheer;

  const PlazaPetCard({
    super.key,
    required this.pet,
    required this.ownerInitial,
    this.isMe = false,
    this.onCheer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isMe
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 3)
            : Border.all(
                color: AppColors.secondary.withValues(alpha: 0.12), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 宠物图标
                _PetIcon(pet: pet),

                const SizedBox(height: 10),

                // 名字
                Text(
                  isMe ? '我 (Lv.${pet.level})' : pet.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // 状态徽章
                _StageBadge(
                  label: pet.growthStageDisplayName,
                  isMe: isMe,
                  status: pet.hungerStatus,
                ),

                const SizedBox(height: 12),

                // 自己：进度条 / 他人：加油按钮
                if (isMe)
                  _ProgressBar(progress: pet.levelProgress)
                else
                  _CheerButton(onTap: onCheer),
              ],
            ),
          ),

          // 左上角头像
          Positioned(
            top: -10,
            left: -10,
            child: _OwnerAvatar(initial: ownerInitial, isMe: isMe),
          ),
        ],
      ),
    );
  }
}

// ── 子组件 ────────────────────────────────────────────────────────────────────

class _PetIcon extends StatelessWidget {
  final PetModel pet;

  const _PetIcon({required this.pet});

  @override
  Widget build(BuildContext context) {
    final size = pet.level >= 8 ? 72.0 : (pet.level >= 5 ? 60.0 : 48.0);

    return Image.asset(
      'assets/images/growth/${pet.growthStage}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  final bool isMe;
  final HungerStatus status;

  const _StageBadge({
    required this.label,
    required this.isMe,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(isMe, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  (Color bg, Color fg) _colors(bool isMe, HungerStatus status) {
    if (isMe) {
      return (AppColors.primary.withValues(alpha: 0.12), AppColors.primary);
    }
    switch (status) {
      case HungerStatus.happy:
      case HungerStatus.normal:
        return (
          AppColors.secondary.withValues(alpha: 0.12),
          AppColors.secondary
        );
      case HungerStatus.hungry:
      case HungerStatus.starving:
        return (
          AppColors.accent.withValues(alpha: 0.2),
          const Color(0xFFB8860B)
        );
      case HungerStatus.critical:
        return (
          AppColors.petCritical.withValues(alpha: 0.15),
          AppColors.petCritical
        );
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: const Color(0xFFEEEEEE),
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

class _CheerButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CheerButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1B5E20),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              '加油',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String initial;
  final bool isMe;

  const _OwnerAvatar({required this.initial, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: isMe ? -0.15 : 0.08,
      child: Container(
        width: isMe ? 40 : 34,
        height: isMe ? 40 : 34,
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 3),
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
