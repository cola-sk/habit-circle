import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../providers/circle_provider.dart';

class InviteFamilyScreen extends ConsumerWidget {
  const InviteFamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(myCircleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ),
        ),
        title: const Text(
          '邀请家人',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B5E20),
          ),
        ),
        centerTitle: true,
      ),
      body: circleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (circle) {
          if (circle == null) {
            return const Center(child: Text('未找到圈子信息'));
          }
          return _InviteContent(
            inviteCode: circle.inviteCode,
            circleName: circle.name,
          );
        },
      ),
    );
  }
}

class _InviteContent extends StatelessWidget {
  final String inviteCode;
  final String circleName;

  const _InviteContent({
    required this.inviteCode,
    required this.circleName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        children: [
          // ── 顶部西瓜横幅 ───────────────────────────────────────
          _WatermelonBanner(circleName: circleName),

          const SizedBox(height: 24),

          // ── 二维码卡片 ────────────────────────────────────────
          _QrCodeCard(inviteCode: inviteCode),

          const SizedBox(height: 20),

          // ── 邀请码卡片 ────────────────────────────────────────
          _InviteCodeCard(inviteCode: inviteCode),

          const SizedBox(height: 20),

          // ── 底部说明 ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF81C784), width: 1.5),
            ),
            child: const Row(
              children: [
                Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '让爸爸妈妈、爷爷奶奶一起来\n见证你的成长吧！',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF388E3C),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 西瓜横幅 ──────────────────────────────────────────────────────────────────

class _WatermelonBanner extends StatelessWidget {
  final String circleName;

  const _WatermelonBanner({required this.circleName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2E7D32),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circleName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '快来一起玩！',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '分享邀请码或扫描二维码\n让家人加入西瓜圈子 🍉',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xCCFFFFFF),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '🍉',
            style: TextStyle(fontSize: 72),
          ),
        ],
      ),
    );
  }
}

// ── 二维码卡片 ────────────────────────────────────────────────────────────────

class _QrCodeCard extends StatelessWidget {
  final String inviteCode;

  const _QrCodeCard({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A4CAF50),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '专属邀请二维码',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '打开「养西瓜」App 扫一扫即可加入',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF81C784),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F5E9), width: 2),
            ),
            child: QrImageView(
              data: 'habitcircle://join?code=$inviteCode',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF2E7D32),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 邀请码卡片 ────────────────────────────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  final String inviteCode;

  const _InviteCodeCard({required this.inviteCode});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '邀请码已复制！',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A4CAF50),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '您的专属邀请码',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF81C784),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copyCode(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF81C784),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inviteCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFFAED581)),
              SizedBox(width: 4),
              Text(
                '点击邀请码即可复制',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAED581),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
