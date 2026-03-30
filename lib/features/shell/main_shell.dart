import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/home',    label: '首页',  icon: Icons.home_rounded),
    (path: '/tasks',   label: '任务',  icon: Icons.task_alt_rounded),
    (path: '/circle',  label: '广场',  icon: Icons.grid_view_rounded),
    (path: '/profile', label: '家长',  icon: Icons.child_care_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      body: child,
      bottomNavigationBar: _WatermelonNavBar(
        activeIndex: activeIndex,
        onTap: (i) => context.go(_tabs[i].path),
        tabs: _tabs,
      ),
    );
  }
}

class _WatermelonNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  final List<({String path, String label, IconData icon})> tabs;

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
              // 广场（index 2）居中凸起样式
              if (i == 2) {
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: activeIndex == i
                            ? AppColors.primary
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (activeIndex == i
                                    ? AppColors.primary
                                    : AppColors.secondary)
                                .withValues(alpha: 0.5),
                            blurRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tabs[i].icon, color: Colors.white, size: 28),
                          const SizedBox(height: 2),
                          Text(
                            tabs[i].label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // 普通 Tab
              final isActive = activeIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 26,
                        color: isActive
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isActive
                              ? AppColors.secondary
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

