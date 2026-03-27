import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    ('/home',    Icons.home_rounded,        Icons.home_outlined,        '首页'),
    ('/tasks',   Icons.checklist_rounded,   Icons.checklist_outlined,   '任务'),
    ('/circle',  Icons.people_rounded,      Icons.people_outline,       '圈子'),
    ('/profile', Icons.person_rounded,      Icons.person_outline,       '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.$1));

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (index) => context.go(_tabs[index].$1),
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.$3),
                activeIcon: Icon(t.$2),
                label: t.$4,
              ),
            )
            .toList(),
      ),
    );
  }
}
