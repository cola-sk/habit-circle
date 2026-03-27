import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: currentUser.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('错误：$e')),
          data: (user) {
            if (user == null) return const SizedBox.shrink();

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 16),
                // ── 头像 & 名字 ─────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          user.childName.isNotEmpty
                              ? user.childName[0]
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.childName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── 信息卡片 ────────────────────────────────────────────
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.group_outlined,
                      label: '我的圈子',
                      value: user.circleId != null ? '已加入' : '未加入',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: '加入时间',
                      value: _formatDate(user.createdAt),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── 退出登录 ────────────────────────────────────────────
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                    foregroundColor: AppColors.secondary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('退出登录'),
                        content: const Text('确定要退出吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => ctx.pop(false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => ctx.pop(true),
                            child: const Text(
                              '退出',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(authRepositoryProvider)
                          .signOut();
                      if (context.mounted) {
                        context.go('/onboarding/welcome');
                      }
                    }
                  },
                  child: const Text('退出登录'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日';
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
