import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(phoneAuthProvider);

    // 登录成功后路由跳转由 GoRouter redirect 处理
    ref.listen(phoneAuthProvider, (_, next) {
      if (next.step == PhoneAuthStep.done) {
        context.go('/onboarding/profile');
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final isCodeSent = authState.step == PhoneAuthStep.codeSent ||
        authState.step == PhoneAuthStep.verifying;
    final isLoading = authState.step == PhoneAuthStep.sending ||
        authState.step == PhoneAuthStep.verifying;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () {
          if (isCodeSent) {
            ref.read(phoneAuthProvider.notifier).reset();
          } else {
            context.pop();
          }
        }),
        title: const Text('手机号登录'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),

            Text(
              isCodeSent ? '输入验证码' : '输入手机号',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            Text(
              isCodeSent
                  ? '验证码已发送至 ${_phoneController.text}'
                  : '家长手机号，用于登录和管理孩子的账号',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const Gap(32),

            if (!isCodeSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 11,
                decoration: const InputDecoration(
                  hintText: '请输入手机号',
                  prefixText: '+86  ',
                  counterText: '',
                ),
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final phone = '+86${_phoneController.text.trim()}';
                        ref.read(phoneAuthProvider.notifier).sendCode(phone);
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('发送验证码'),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '6 位验证码',
                  counterText: '',
                ),
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(phoneAuthProvider.notifier).verifyCode(
                              _codeController.text.trim(),
                            );
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('验证并登录'),
              ),
              const Gap(16),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(phoneAuthProvider.notifier).sendCode(
                            '+86${_phoneController.text.trim()}',
                          ),
                  child: const Text('重新发送验证码'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
