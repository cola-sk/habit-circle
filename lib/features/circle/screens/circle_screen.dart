import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pet_species.dart';
import '../../../providers/circle_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/pet_model.dart';

class CircleScreen extends ConsumerWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(myCircleProvider);

    return circleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('加载失败: $e')),
      ),
      data: (circle) {
        if (circle == null) {
          return const _NoCirclePlaceholder();
        }

        return _CircleContent(
          circleName: circle.name,
          memberUids: circle.memberUids,
        );
      },
    );
  }
}

class _CircleContent extends ConsumerWidget {
  final String circleName;
  final List<String> memberUids;

  const _CircleContent({
    required this.circleName,
    required this.memberUids,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(circlePetsProvider);
    final currentUid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(circleName),
            Text(
              '${memberUids.length} 位小伙伴',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (pets) {
          // 按今日状态排序（开心的在前），自己的宠物始终第一
          final sorted = [...pets]..sort((a, b) {
              if (a.ownerId == currentUid) return -1;
              if (b.ownerId == currentUid) return 1;
              return a.hungerStatus.index.compareTo(b.hungerStatus.index);
            });

          return CustomScrollView(
            slivers: [
              // 今日积分榜 Top 3
              SliverToBoxAdapter(
                child: _LeaderboardWidget(pets: pets),
              ),

              // 宠物网格
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PetCard(
                      pet: sorted[index],
                      isMe: sorted[index].ownerId == currentUid,
                    ),
                    childCount: sorted.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final bool isMe;

  const _PetCard({required this.pet, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(pet.hungerStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('我',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),

          const Gap(4),

          Text(
            pet.species.emoji,
            style: TextStyle(
              fontSize: pet.level >= 7 ? 32 : (pet.level >= 4 ? 28 : 24),
            ),
          ),

          const Gap(4),

          Text(
            pet.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          const Gap(2),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusEmoji(pet.hungerStatus),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(HungerStatus s) {
    switch (s) {
      case HungerStatus.happy:    return AppColors.petHappy;
      case HungerStatus.normal:   return AppColors.petNormal;
      case HungerStatus.hungry:   return AppColors.petHungry;
      case HungerStatus.starving: return AppColors.petStarving;
      case HungerStatus.critical: return AppColors.petCritical;
    }
  }

  String _statusEmoji(HungerStatus s) {
    switch (s) {
      case HungerStatus.happy:    return '😄 开心';
      case HungerStatus.normal:   return '😊 正常';
      case HungerStatus.hungry:   return '😕 饿了';
      case HungerStatus.starving: return '😢 很饿';
      case HungerStatus.critical: return '💀 快救我';
    }
  }
}

class _LeaderboardWidget extends StatelessWidget {
  final List<PetModel> pets;

  const _LeaderboardWidget({required this.pets});

  @override
  Widget build(BuildContext context) {
    // TODO: 需要结合今日积分数据排序，目前按 totalPoints 示意
    final sorted = [...pets]
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final top3 = sorted.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D96FF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 今日最勤奋',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              top3.length,
              (i) => _RankItem(
                rank: i + 1,
                pet: top3[i],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankItem extends StatelessWidget {
  final int rank;
  final PetModel pet;

  const _RankItem({required this.rank, required this.pet});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return Column(
      children: [
        Text(medals[rank - 1], style: const TextStyle(fontSize: 20)),
        const Gap(4),
        Text(
          pet.species.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const Gap(2),
        Text(
          pet.name,
          style: const TextStyle(fontSize: 11, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NoCirclePlaceholder extends StatelessWidget {
  const _NoCirclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('圈子')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🌐', style: TextStyle(fontSize: 64)),
            Gap(16),
            Text(
              '还没有加入圈子',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(8),
            Text(
              '去「我的」页面创建或加入一个圈子',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
