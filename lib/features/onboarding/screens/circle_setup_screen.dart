import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/circle_provider.dart';

class CircleSetupScreen extends ConsumerStatefulWidget {
  const CircleSetupScreen({super.key});

  @override
  ConsumerState<CircleSetupScreen> createState() => _CircleSetupScreenState();
}

class _CircleSetupScreenState extends ConsumerState<CircleSetupScreen> {
  bool _showCreate = false;
  bool _showJoin = false;
  final _circleNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _circleNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(circleSetupProvider);
    final isLoading = setupState is AsyncLoading;

    ref.listen(circleSetupProvider, (_, next) {
      if (next is AsyncData) {
        context.go('/home');
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('加入圈子'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '加入你们的圈子',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            const Text(
              '和小伙伴的家长一起，互相督促学习',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),

            const Gap(36),

            // 创建圈子
            _OptionCard(
              emoji: '🏠',
              title: '创建新圈子',
              subtitle: '作为第一个家长，邀请其他人加入',
              isExpanded: _showCreate,
              onTap: () => setState(() {
                _showCreate = !_showCreate;
                _showJoin = false;
              }),
            ),

            if (_showCreate) ...[
              const Gap(12),
              TextField(
                controller: _circleNameController,
                maxLength: 15,
                decoration: const InputDecoration(
                  hintText: '圈子名称（如：三班学习圈）',
                  counterText: '',
                ),
              ),
              const Gap(12),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final name = _circleNameController.text.trim();
                        if (name.isEmpty) return;
                        ref.read(circleSetupProvider.notifier).createCircle(name);
                      },
                child: const Text('创建圈子'),
              ),
            ],

            const Gap(16),

            // 加入圈子
            _OptionCard(
              emoji: '🔗',
              title: '加入已有圈子',
              subtitle: '输入邀请码或扫描二维码加入',
              isExpanded: _showJoin,
              onTap: () => setState(() {
                _showJoin = !_showJoin;
                _showCreate = false;
              }),
            ),

            if (_showJoin) ...[
              const Gap(12),
              TextField(
                controller: _inviteCodeController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: '6 位邀请码',
                  counterText: '',
                ),
              ),
              const Gap(12),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final code = _inviteCodeController.text.trim();
                        if (code.length != 6) return;
                        final success = await ref
                            .read(circleSetupProvider.notifier)
                            .joinCircle(code);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('邀请码无效或圈子已满')),
                          );
                        }
                      },
                child: const Text('加入圈子'),
              ),
            ],

            const Spacer(),

            // 暂时跳过
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  '稍后再说',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
