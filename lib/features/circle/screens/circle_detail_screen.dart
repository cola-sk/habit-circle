import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/pet_species.dart';
import '../../../models/circle_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/circle_provider.dart';
import '../../../repositories/circle_repository.dart';

/// 按圈子 ID 获取详情（供详情页使用，可公开访问）
final _circleDetailProvider =
    FutureProvider.family<CircleModel?, String>((ref, id) {
  return ref.watch(circleRepositoryProvider).fetchCircle(id);
});

class CircleDetailScreen extends ConsumerWidget {
  final String circleId;
  const CircleDetailScreen({super.key, required this.circleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(_circleDetailProvider(circleId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final joinState = ref.watch(circleSetupProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2FAE8),
      body: circleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (circle) {
          if (circle == null) {
            return const Center(child: Text('圈子不存在'));
          }
          final isLoggedIn = currentUser != null;
          final alreadyMember = isLoggedIn &&
              circle.memberUids.contains(currentUser.uid);

          return CustomScrollView(
            slivers: [
              _CircleAppBar(circle: circle),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsRow(circle: circle),
                    const SizedBox(height: 20),
                    _SectionTitle(title: '🌱 成员养西瓜进展'),
                    const SizedBox(height: 12),
                    ...circle.members.map((m) => _MemberCard(member: m)),
                    if (circle.members.isEmpty)
                      const _EmptyMembers(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: circleAsync.whenData((circle) {
        if (circle == null) return null;
        final isLoggedIn = currentUser != null;
        final alreadyMember =
            isLoggedIn && circle.memberUids.contains(currentUser.uid);

        if (alreadyMember) {
          return _BottomBar(
            child: _AlreadyJoinedBadge(),
          );
        }
        return _BottomBar(
          child: _JoinButton(
            isLoggedIn: isLoggedIn,
            loading: joinState.isLoading,
            onJoin: () async {
              final success = await ref
                  .read(circleSetupProvider.notifier)
                  .joinCircleById(circle.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '🎉 成功加入「${circle.name}」！' : '加入失败，请重试'),
                    backgroundColor:
                        success ? const Color(0xFF4CAF50) : Colors.red,
                  ),
                );
                if (success) {
                  ref.invalidate(_circleDetailProvider(circle.id));
                  context.pop();
                }
              }
            },
            onLogin: () => context.go('/onboarding/auth'),
          ),
        );
      }).value,
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────
class _CircleAppBar extends StatelessWidget {
  final CircleModel circle;
  const _CircleAppBar({required this.circle});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
            ),
          ),
          child: const Center(
            child: Text('🍉', style: TextStyle(fontSize: 64)),
          ),
        ),
        title: Text(
          circle.name,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
      ),
    );
  }
}

// ── 统计行 ──────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final CircleModel circle;
  const _StatsRow({required this.circle});

  @override
  Widget build(BuildContext context) {
    final totalPoints = circle.members
        .where((m) => m.pet != null)
        .fold(0, (sum, m) => sum + (m.pet?.totalPoints ?? 0));

    return Row(
      children: [
        _StatChip(icon: '👦', value: '${circle.memberCount}', label: '成员'),
        const SizedBox(width: 10),
        _StatChip(icon: '⭐', value: '$totalPoints', label: '总水滴'),
        const SizedBox(width: 10),
        _StatChip(
          icon: '🌟',
          value: circle.members.isNotEmpty
              ? (circle.members
                          .where((m) => m.pet != null)
                          .map((m) => m.pet!.level)
                          .fold(0, (a, b) => a + b) /
                      circle.members
                          .where((m) => m.pet != null)
                          .length)
                  .toStringAsFixed(1)
              : '0',
          label: '平均等级',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6CC24A), width: 1.5),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF2E7D32))),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7B9E7B))),
          ],
        ),
      ),
    );
  }
}

// ── 小节标题 ─────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2E7D32)));
  }
}

// ── 成员卡片 ─────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final CircleMember member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final pet = member.pet;
    final stage =
        pet != null ? PetLevelThresholds.growthStageFromPoints(pet.totalPoints) : null;
    final stageName = stage?.displayName ?? '未知';
    final level = pet?.level ?? 1;
    final totalPoints = pet?.totalPoints ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
      ),
      child: Row(
        children: [
          // 西瓜成长阶段图
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: stage != null
                ? Image.asset(
                    'assets/images/growth/${stage.name}.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 56, height: 56,
                            child: Center(child: Text('🍉', style: TextStyle(fontSize: 32)))),
                  )
                : const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(child: Text('🍉', style: TextStyle(fontSize: 32)))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.childName.isEmpty ? '神秘小朋友' : member.childName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag('Lv.$level', const Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    _Tag(stageName, const Color(0xFFFFA726)),
                  ],
                ),
                const SizedBox(height: 6),
                // 积分进度条
                LinearProgressIndicator(
                  value: pet != null ? pet.levelProgress : 0,
                  backgroundColor: const Color(0xFFE8F5E9),
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 3),
                Text(
                  '累计 $totalPoints 分',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text('暂时没有成员，快来加入吧！',
            style: TextStyle(color: Color(0xFF9E9E9E))),
      ),
    );
  }
}

// ── 底部操作栏 ────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final Widget? child;
  const _BottomBar({this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
      ),
      child: child,
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isLoggedIn;
  final bool loading;
  final VoidCallback onJoin;
  final VoidCallback onLogin;
  const _JoinButton(
      {required this.isLoggedIn,
      required this.loading,
      required this.onJoin,
      required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : (isLoggedIn ? onJoin : onLogin),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: loading ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2E7D32), width: 2),
          boxShadow: loading
              ? []
              : const [
                  BoxShadow(
                      color: Color(0xFF2E7D32),
                      blurRadius: 0,
                      offset: Offset(3, 4))
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(
                  isLoggedIn ? '🌱 加入这个圈子' : '登录后加入圈子',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}

class _AlreadyJoinedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF6CC24A), width: 2),
      ),
      child: const Center(
        child: Text(
          '✅ 已加入此圈子',
          style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
