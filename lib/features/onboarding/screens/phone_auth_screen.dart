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
      backgroundColor: const Color(0xFFF2FAE8),
      body: Stack(
        children: [
          // 渐变背景
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE6F7D0), Color(0xFFFFFBEC)],
                ),
              ),
            ),
          ),
          // 装饰元素：散落的西瓜图案
          const _WatermelonDecorations(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 返回按钮（仅验证码步骤显示）
                  if (isCodeSent)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(onTap: () => _onBack(isCodeSent)),
                    ),
                  const Gap(8),
                  // 吉祥物 + 品牌区
                  _HeroSection(isCodeSent: isCodeSent),
                  const Gap(20),
                  // 表单卡片
                  _FormCard(
                    isCodeSent: isCodeSent,
                    isLoading: isLoading,
                    phoneController: _phoneController,
                    codeController: _codeController,
                    devCode: authState.devCode,
                    onSendCode: () {
                      ref
                          .read(phoneAuthProvider.notifier)
                          .sendCode(_phoneController.text.trim());
                    },
                    onVerify: () {
                      ref
                          .read(phoneAuthProvider.notifier)
                          .verifyCode(_codeController.text.trim());
                    },
                    onResend: () {
                      ref
                          .read(phoneAuthProvider.notifier)
                          .sendCode(_phoneController.text.trim());
                    },
                  ),
                  const Gap(16),
                  const Center(
                    child: Text(
                      '登录即代表同意《用户协议》与《隐私政策》',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA0A8A0),
                        fontWeight: FontWeight.w500,
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

// ── 散落的西瓜装饰图案 ──────────────────────────────────────────
class _WatermelonDecorations extends StatelessWidget {
  const _WatermelonDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(top: 28, left: 18, child: _WmEmoji('🍉', 32)),
          Positioned(top: 60, right: 30, child: _WmEmoji('⭐', 20)),
          Positioned(top: 140, left: 12, child: _WmEmoji('✨', 18)),
          Positioned(top: 180, right: 14, child: _WmEmoji('🌿', 22)),
          Positioned(top: 260, left: 30, child: _WmEmoji('🌱', 22)),
          Positioned(bottom: 180, right: 20, child: _WmEmoji('🍀', 24)),
          Positioned(bottom: 120, left: 16, child: _WmEmoji('⭐', 18)),
          Positioned(bottom: 60, right: 34, child: _WmEmoji('🍉', 28)),
        ],
      ),
    );
  }
}

class _WmEmoji extends StatelessWidget {
  final String emoji;
  final double size;
  const _WmEmoji(this.emoji, this.size);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Transform.rotate(
        angle: (size % 7 - 3) * 0.2,
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }
}

// ── 返回按钮 ──────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF6CC24A), width: 2),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: Color(0xFF4A9E2A)),
      ),
    );
  }
}

// ── 吉祥物 + 品牌区 ───────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool isCodeSent;
  const _HeroSection({required this.isCodeSent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isCodeSent
              ? const SizedBox(height: 8)
              : SizedBox(
                  width: 220,
                  height: 220,
                  child: Image.asset(
                    'assets/images/login_watermelon_mascot.png',
                    fit: BoxFit.contain,
                  ),
                ),
        ),
        const Gap(8),
        // 品牌名：贴纸风格
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF2E7D32), width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x552E7D32),
                blurRadius: 0,
                offset: Offset(3, 4),
              ),
            ],
          ),
          child: const Text(
            '🍉 养西瓜',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              height: 1.2,
            ),
          ),
        ),
        const Gap(10),
        // 副标题：彩色标签风格
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFF9A825), width: 1.5),
          ),
          child: const Text(
            '✨ 陪伴孩子养成好习惯',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF795548),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 表单卡片 ──────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final bool isCodeSent;
  final bool isLoading;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final String? devCode;
  final VoidCallback onSendCode;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _FormCard({
    required this.isCodeSent,
    required this.isLoading,
    required this.phoneController,
    required this.codeController,
    required this.devCode,
    required this.onSendCode,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF6CC24A), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF6CC24A),
            blurRadius: 0,
            offset: Offset(4, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 卡片标题
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isCodeSent ? '🔐 输入验证码' : '📱 手机号登录',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            isCodeSent
                ? '验证码已发送至 ${phoneController.text}'
                : '家长手机号，用于登录和管理孩子账号',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7B9E7B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(18),
          if (!isCodeSent) ...[
            _InputField(
              controller: phoneController,
              hintText: '请输入手机号',
              prefixText: '+86 ',
              keyboardType: TextInputType.phone,
              maxLength: 11,
            ),
            const Gap(14),
            _PrimaryButton(
              label: '发送验证码 →',
              loading: isLoading,
              onTap: onSendCode,
            ),
          ] else ...[
            _InputField(
              controller: codeController,
              hintText: '请输入 6 位验证码',
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
            ),
            if (devCode != null) ...[
              const Gap(8),
              Center(
                child: Text(
                  '调试验证码：$devCode',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Gap(14),
            _PrimaryButton(
              label: '验证并登录 🎉',
              loading: isLoading,
              onTap: onVerify,
            ),
            const Gap(4),
            TextButton(
              onPressed: isLoading ? null : onResend,
              child: const Text(
                '重新发送验证码',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 输入框 ────────────────────────────────────────────────────
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
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF2E7D32),
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Color(0xFF81C784),
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF1FAF1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFA5D6A7), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFA5D6A7), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF4CAF50), width: 2.5),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ── 主按钮 ────────────────────────────────────────────────────
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
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 54,
        decoration: BoxDecoration(
          color: loading ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2E7D32), width: 2.5),
          boxShadow: loading
              ? []
              : const [
                  BoxShadow(
                    color: Color(0xFF2E7D32),
                    blurRadius: 0,
                    offset: Offset(3, 4),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
