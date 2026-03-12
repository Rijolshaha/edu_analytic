// lib/screens/shell/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _routes = [
    '/dashboard', '/courses', '/students', '/prediction', '/statistics',
  ];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.menu_book_rounded,
    Icons.people_alt_rounded,
    Icons.psychology_rounded,
    Icons.bar_chart_rounded,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _routes.indexWhere((r) => location.startsWith(r));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = [AppLocalizations.of(context)!.dashboard, AppLocalizations.of(context)!.courses, AppLocalizations.of(context)!.students, AppLocalizations.of(context)!.prediction, AppLocalizations.of(context)!.statistics];
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_routes[i]),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(_routes.length, (i) => NavigationDestination(
          icon: Icon(_icons[i],
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          selectedIcon: Icon(_icons[i], color: AppColors.primary),
          label: labels[i],
        )),
      ),
    );
  }
}