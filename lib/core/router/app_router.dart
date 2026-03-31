import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/phone_auth_screen.dart';
import '../../features/onboarding/screens/create_profile_screen.dart';
import '../../features/onboarding/screens/choose_pet_screen.dart';
import '../../features/onboarding/screens/circle_setup_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/circle/screens/circle_screen.dart';
import '../../features/circle/screens/circle_detail_screen.dart';
import '../../features/growth/screens/growth_details_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/circle/screens/invite_family_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // ref.read（不是 watch），路由器只创建一次，不随状态变化重建
  final authNotifier = ref.read(authStateNotifierProvider);

  final router = GoRouter(
    initialLocation: authNotifier.isLoggedIn ? '/home' : '/circle',
    // 登录状态变化时，GoRouter 自动重新评估 redirect（不重建路由器）
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = authNotifier.isLoggedIn;
      final loc = state.matchedLocation;

      // 已登录：放行所有路由
      if (loggedIn) return null;

      // 未登录：onboarding 路由放行，圈子广场 + 圈子详情放行
      if (loc.startsWith('/onboarding') || loc.startsWith('/circle')) return null;
      // home/tasks/profile 跳登录页
      return '/onboarding/auth';
    },
    routes: [
      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/auth',
        builder: (_, __) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (_, __) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/pet',
        builder: (_, __) => const ChoosePetScreen(),
      ),
      GoRoute(
        path: '/onboarding/circle',
        builder: (_, __) => const CircleSetupScreen(),
      ),
      GoRoute(
        path: '/growth',
        redirect: (_, __) => '/profile/growth',
      ),

      // ── Main App（带 BottomNavBar 的 Shell）────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const TasksScreen(),
          ),
          GoRoute(
            path: '/circle',
            builder: (_, __) => const CircleScreen(),
            routes: [
              GoRoute(
                path: 'invite',
                builder: (_, __) => const InviteFamilyScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => CircleDetailScreen(
                  circleId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'growth',
                builder: (_, __) => const GrowthDetailsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // 监听 401 事件：清除登录态（refreshListenable 会触发 redirect 自动跳走）
  ref.listen(unauthenticatedEventProvider, (_, next) {
    if (next.hasValue) {
      authNotifier.logout();
      router.go('/circle');
    }
  });

  return router;
});
