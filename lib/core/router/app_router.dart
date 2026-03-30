import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/circle_provider.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/phone_auth_screen.dart';
import '../../features/onboarding/screens/create_profile_screen.dart';
import '../../features/onboarding/screens/choose_pet_screen.dart';
import '../../features/onboarding/screens/circle_setup_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/circle/screens/circle_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // 监听 auth 状态，做路由重定向
    final authState = ref.watch(isLoggedInProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      // TODO: 恢复登录校验
      // final isLoggedIn = authState.valueOrNull == true;
      // if (!isLoggedIn) {
      //   if (state.matchedLocation.startsWith('/onboarding')) return null;
      //   return '/onboarding/welcome';
      // }
      return null;
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
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
