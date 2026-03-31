import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/circle_provider.dart';
import '../../providers/pet_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/home',    label: '首页',  icon: Icons.home_rounded,         requiresAuth: true),
    (path: '/tasks',   label: '任务',  icon: Icons.task_alt_rounded,     requiresAuth: true),
    (path: '/circle',  label: '广场',  icon: Icons.grid_view_rounded,    requiresAuth: false),
    (path: '/profile', label: '家长',  icon: Icons.child_care_rounded,   requiresAuth: true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      body: child,
      bottomNavigationBar: _WatermelonNavBar(
        activeIndex: activeIndex,
        onTap: (i) {
          final tab = _tabs[i];
          // 每次切换到圈子广场时，刷新圈子和当前用户积分数据
          if (tab.path == '/circle') {
            ref.invalidate(circlePetsProvider);
            ref.invalidate(myPetProvider);
          }
          if (tab.requiresAuth && !isLoggedIn) {
            context.go('/onboarding/auth');
          } else {
            context.go(tab.path);
          }
        },
        tabs: _tabs,
      ),
    );
  }
}

class _WatermelonNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  final List<({String path, String label, IconData icon, bool requiresAuth})> tabs;

  const _WatermelonNavBar({
    required this.activeIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(tabs.length, (i) {
              final isActive = activeIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 选中时加一个圆角背景底
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tabs[i].icon,
                          size: 26,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

