import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/circle_model.dart';
import '../../../models/pet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/circle_provider.dart';
import '../../../providers/pet_provider.dart';
import '../widgets/plaza_pet_card_widget.dart';

class CircleScreen extends ConsumerWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final hasCircle = currentUser?.circleId != null;

    return DefaultTabController(
      length: hasCircle ? 2 : 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        appBar: AppBar(
          title: const Text(
            '西瓜地',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF1B5E20)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            tabs: [
              if (hasCircle) const Tab(text: '我的'),
              const Tab(text: '全部'),
            ],
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 14),
            indicatorColor: AppColors.secondary,
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: TabBarView(
          children: [
            if (hasCircle) const _MyCircleTab(),
            const _AllCirclesTab(),
          ],
        ),
      ),
    );
  }
}

// ── 全部圈子 Tab ──────────────────────────────────────────────
class _AllCirclesTab extends ConsumerWidget {
  const _AllCirclesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allCirclesProvider);

    return allAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (circles) {
        if (circles.isEmpty) {
          return const Center(
            child: Text('暂时还没有圈子，去创建第一个吧！',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(allCirclesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: circles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CircleCard(
              circle: circles[i],
              onTap: () => context.push('/circle/${circles[i].id}'),
            ),
          ),
        );
      },
    );
  }
}

// ── 圈子卡片 ──────────────────────────────────────────────────
class _CircleCard extends StatelessWidget {
  final CircleModel circle;
  final VoidCallback onTap;
  const _CircleCard({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 取最高等级的3个宠物做预览
    final previewPets = [...circle.members]
      ..sort((a, b) =>
          (b.pet?.level ?? 0).compareTo(a.pet?.level ?? 0));
    final preview = previewPets.take(3).toList();
    final totalPoints = circle.members
        .fold(0, (sum, m) => sum + (m.pet?.totalPoints ?? 0));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF6CC24A), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0xFF6CC24A),
                blurRadius: 0,
                offset: Offset(3, 4))
          ],
        ),
        child: Row(
          children: [
            // 西瓜图标
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                  child: Text('🍉', style: TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip('👦 ${circle.memberCount} 人'),
                      const SizedBox(width: 6),
                      _InfoChip('⭐ $totalPoints 分'),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...preview.map((m) => Padding(
                              padding:
                                  const EdgeInsets.only(right: 4),
                              child: _MiniAvatar(
                                  name: m.childName),
                            )),
                        if (circle.memberCount > 3)
                          Text(
                            '+${circle.memberCount - 3}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF6CC24A)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700)),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String name;
  const _MiniAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0] : '?';
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ── 我的圈子 Tab ──────────────────────────────────────────────
class _MyCircleTab extends ConsumerWidget {
  const _MyCircleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(myCircleProvider);

    return circleAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (circle) {
        if (circle == null) return const _NoCirclePlaceholder();
        return _PlazaContent(circle: circle);
      },
    );
  }
}

// ── 主内容 ───────────────────────────────────────────────────────────────────

class _PlazaContent extends ConsumerWidget {
  final CircleModel circle;

  const _PlazaContent({required this.circle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(circlePetsProvider);
    final currentUid = ref.watch(currentUidProvider);
    // 直接从本地缓存取最新积分，不依赖圈子接口延迟刷新
    final myPetLatest = ref.watch(myPetProvider).valueOrNull;

    return ColoredBox(
      color: const Color(0xFFE8F5E9),
      child: Stack(
        children: [
          // 点状背景装饰
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),

          petsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
            data: (pets) => _PlazaBody(
              circle: circle,
              pets: pets,
              currentUid: currentUid,
              myPetLatest: myPetLatest,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlazaBody extends StatelessWidget {
  final CircleModel circle;
  final List<PetModel> pets;
  final String? currentUid;
  final PetModel? myPetLatest;

  const _PlazaBody({
    required this.circle,
    required this.pets,
    required this.currentUid,
    this.myPetLatest,
  });

  @override
  Widget build(BuildContext context) {
    // 自己在前，其余按等级降序
    final sorted = [...pets]..sort((a, b) {
        if (a.ownerId == currentUid) return -1;
        if (b.ownerId == currentUid) return 1;
        return b.level.compareTo(a.level);
      });

    // 找自己的宠物用于统计（优先用本地最新缓存，兜底从圈子列表匹配）
    final myPetFromList = pets.where((p) => p.ownerId == currentUid).firstOrNull;
    final myPet = myPetLatest ?? myPetFromList;
    final myRank = sorted.indexWhere((p) => p.ownerId == currentUid) + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        // ── 邀请横幅 ─────────────────────────────────
        _InviteBanner(circleName: circle.name),

        const Gap(16),

        // ── 统计行 ──────────────────────────────────
        _StatsRow(rank: myRank, points: myPet?.totalPoints ?? 0),

        const Gap(24),

        // ── 成长地标题 ──────────────────────────────
        _SectionHeader(memberCount: circle.memberUids.length),

        const Gap(16),

        // ── 宠物卡片网格 ────────────────────────────
        _PetGrid(pets: sorted, currentUid: currentUid),

        const Gap(24),

        // ── 园丁秘籍 ────────────────────────────────
        const _TipCard(),
      ],
    );
  }
}

// ── 邀请横幅 ─────────────────────────────────────────────────────────────────

class _InviteBanner extends StatelessWidget {
  final String circleName;

  const _InviteBanner({required this.circleName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4D4D), Color(0xFFFF8A8A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD32F2F),
            offset: Offset(0, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰图标
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(
              Icons.park_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🍉', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text(
                    circleName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '叫上小伙伴，一起把西瓜\n种得又大又甜！',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/circle/invite'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20000000),
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_add_rounded,
                          color: Color(0xFFFF4D4D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '邀请家人',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF4D4D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 统计行 ────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int rank;
  final int points;

  const _StatsRow({required this.rank, required this.points});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFFFD700),
            label: '我的排名',
            value: rank > 0 ? '第 $rank 名' : '--',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.secondary,
            label: '总积分',
            value: '$points',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0E0E0),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 成长地标题 ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final int memberCount;

  const _SectionHeader({required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.energy_savings_leaf_rounded,
            color: AppColors.secondary, size: 28),
        const SizedBox(width: 8),
        const Text(
          '西瓜成长地',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF2E7D32),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            '$memberCount 位园丁',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 宠物网格 ──────────────────────────────────────────────────────────────────

class _PetGrid extends StatelessWidget {
  final List<PetModel> pets;
  final String? currentUid;

  const _PetGrid({required this.pets, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '圈子里还没有西瓜 🌱',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.76,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        final isMe = pet.ownerId == currentUid;
        // ownerName 首字做头像；无 ownerName 时降级到宠物名首字
        final displayName = pet.ownerName.isNotEmpty ? pet.ownerName : pet.name;
        final initial = displayName.isNotEmpty ? displayName[0] : '?';
        return PlazaPetCard(
          pet: pet,
          ownerInitial: initial,
          ownerName: pet.ownerName,
          isMe: isMe,
          onCheer: isMe ? null : () {/* TODO: 加油功能 */},
        );
      },
    );
  }
}

// ── 园丁秘籍 ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFEEEEEE),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Color(0xFFFFD700), size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '园丁秘籍',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '给小伙伴的西瓜加油，一起把西瓜养得又大又甜！',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ── 无圈子占位 ────────────────────────────────────────────────────────────────

class _NoCirclePlaceholder extends StatelessWidget {
  const _NoCirclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🌱', style: TextStyle(fontSize: 72)),
            Gap(16),
            Text(
              '还没有加入圈子',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(8),
            Text(
              '去「家长」页面创建或加入一个圈子',
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 点状背景装饰画笔 ──────────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA5D6A7)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


