import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController(text: '13800000000');
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

    ref.listen(phoneAuthProvider, (prev, next) {
      if (next.step == PhoneAuthStep.done) {
        context.go(next.nextRoute ?? '/home');
      }

      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFB02500),
          ),
        );
      }
    });

    final isCodeSent = authState.step == PhoneAuthStep.codeSent ||
        authState.step == PhoneAuthStep.verifying;
    final isLoading = authState.step == PhoneAuthStep.sending ||
        authState.step == PhoneAuthStep.verifying;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF8FE),
      body: Stack(
        children: [
          const Positioned(
            top: -80,
            left: -80,
            child: _DecorGlow(
              size: 220,
              color: Color(0x44FDD34D),
            ),
          ),
          const Positioned(
            top: 80,
            right: -70,
            child: _DecorGlow(
              size: 200,
              color: Color(0x3391F78E),
            ),
          ),
          const Positioned(
            bottom: -60,
            right: -40,
            child: _DecorGlow(
              size: 180,
              color: Color(0x33FF7671),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _onBack(isCodeSent),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.85),
                          foregroundColor: const Color(0xFF273034),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.local_florist,
                        size: 30,
                        color: Color(0xFFB21D27),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Grow Watermelon',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB21D27),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: Image.asset(
                        'assets/images/login_watermelon_mascot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Center(
                    child: Text(
                      '养西瓜',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB21D27),
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      '陪伴孩子养成好习惯',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF545D62),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14B21D27),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isCodeSent ? '输入验证码' : '手机号登录',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF273034),
                          ),
                        ),
                        const Gap(6),
                        Text(
                          isCodeSent
                              ? '验证码已发送至 ${_phoneController.text}'
                              : '家长手机号，用于登录和管理孩子账号',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F787D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(16),
                        if (!isCodeSent) ...[
                          _InputField(
                            controller: _phoneController,
                            hintText: '请输入手机号',
                            prefixText: '+86 ',
                            keyboardType: TextInputType.phone,
                            maxLength: 11,
                          ),
                          const Gap(12),
                          _PrimaryButton(
                            label: '发送验证码',
                            loading: isLoading,
                            onTap: () {
                              final phone = _phoneController.text.trim();
                              ref
                                  .read(phoneAuthProvider.notifier)
                                  .sendCode(phone);
                            },
                          ),
                        ] else ...[
                          _InputField(
                            controller: _codeController,
                            hintText: '请输入 6 位验证码',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofocus: true,
                          ),
                          if (authState.devCode != null) ...[
                            const Gap(8),
                            Center(
                              child: Text(
                                '调试验证码：${authState.devCode}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF545D62),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Gap(12),
                          _PrimaryButton(
                            label: '验证并登录',
                            loading: isLoading,
                            onTap: () {
                              ref
                                  .read(phoneAuthProvider.notifier)
                                  .verifyCode(_codeController.text.trim());
                            },
                          ),
                          const Gap(4),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    ref
                                        .read(phoneAuthProvider.notifier)
                                        .sendCode(
                                          _phoneController.text.trim(),
                                        );
                                  },
                            child: const Text(
                              '重新发送验证码',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB21D27),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Gap(14),
                  const Center(
                    child: Text(
                      '登录即代表同意《用户协议》与《隐私政策》',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF959EA4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBack(bool isCodeSent) {
    if (isCodeSent) {
      ref.read(phoneAuthProvider.notifier).reset();
      _codeController.clear();
    } else {
      context.pop();
    }
  }
}

class _DecorGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? prefixText;
  final TextInputType keyboardType;
  final int maxLength;
  final bool autofocus;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.prefixText,
    required this.keyboardType,
    required this.maxLength,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF7FBFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x44A5AEB4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x44A5AEB4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB21D27), width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB21D27),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
    );
  }
}
