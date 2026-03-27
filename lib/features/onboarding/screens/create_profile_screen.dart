import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/user_repository.dart';
import '../../../models/user_model.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建档案')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            const Text(
              '孩子叫什么名字？',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            const Text(
              '这将显示在圈子里，填写昵称就好',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(32),
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: '孩子的昵称或名字',
                counterText: '',
              ),
            ),
            const Gap(32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('下一步'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入孩子的名字')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;

      await ref.read(userRepositoryProvider).createUser(
            UserModel(
              uid: uid,
              phone: '',
              childName: name,
              createdAt: DateTime.now(),
            ),
          );

      if (mounted) context.go('/onboarding/pet');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
