import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/cheer_message_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cheer_provider.dart';
import '../../providers/circle_provider.dart';
import '../../providers/pet_provider.dart';
import '../../repositories/cheer_repository.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/home',    label: '我的',   icon: Icons.home_rounded,       requiresAuth: true),
    (path: '/tasks',   label: '任务',   icon: Icons.task_alt_rounded,   requiresAuth: true),
    (path: '/circle',  label: '西瓜地', icon: Icons.grid_view_rounded,  requiresAuth: false),
    (path: '/profile', label: '家长',   icon: Icons.child_care_rounded, requiresAuth: true),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _cheerTriggerPaths = {'/circle', '/profile'};

  /// 本次 App 会话内已展示过的加油者（内存缓存，防止 resume 重复弹）
  final Set<String> _sessionShownCheerers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // App 首次打开
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCheers());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkCheers();
  }

  Future<void> _checkCheers() async {
    if (!mounted) return;
    final isLoggedIn = ref.read(authStateNotifierProvider).isLoggedIn;
    if (!isLoggedIn) return;

    ref.invalidate(todayCheersProvider);
    final cheerers = await ref.read(todayCheersProvider.future);
    if (!mounted) return;

    // 过滤本次会话内已弹过的（防 resume 重复弹）
    final newCheerers =
        cheerers.where((c) => !_sessionShownCheerers.contains(c)).toList();
    if (newCheerers.isEmpty) return;

    _sessionShownCheerers.addAll(newCheerers);
    // 先标记已读（乐观更新），防止弹窗期间切后台再回来重复触发
    await ref.read(cheerRepositoryProvider).markTodayCheersAsRead();
    await CheerMessageDialog.showIfNeeded(context, newCheerers);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex =
        MainShell._tabs.indexWhere((t) => location.startsWith(t.path));
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _WatermelonNavBar(
        activeIndex: activeIndex,
        onTap: (i) {
          final tab = MainShell._tabs[i];
          if (tab.path == '/circle') {
            ref.invalidate(circlePetsProvider);
            ref.invalidate(myPetProvider);
          }
          // 进入广场或家长页时触发加油检查
          if (_cheerTriggerPaths.contains(tab.path)) {
            _checkCheers();
          }
          if (tab.requiresAuth && !isLoggedIn) {
            context.go('/onboarding/auth');
          } else {
            context.go(tab.path);
          }
        },
        tabs: MainShell._tabs,
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

