// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import '../services/auth_service.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(currentUserProvider);
    final location = GoRouterState.of(context).uri.path;

    final items = [
      _DrawerItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      _DrawerItem(Icons.menu_book_rounded, 'Kurslar', '/courses'),
      _DrawerItem(Icons.group_rounded, 'Guruhlar', '/groups'),
      _DrawerItem(Icons.people_alt_rounded, 'O\'quvchilar', '/students'),
      _DrawerItem(Icons.psychology_rounded, 'Prognoz', '/prediction'),
      _DrawerItem(Icons.bar_chart_rounded, 'Statistika', '/statistics'),
      _DrawerItem(Icons.settings_rounded, 'Sozlamalar', '/settings'),
    ];

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Text('EduAnalytics',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(user?.name ?? 'O\'qituvchi',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(user?.email ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: items
                  .map((item) => _buildNavItem(context, item, location, isDark))
                  .toList(),
            ),
          ),

          // Bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                // Theme toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(isDark ? 'Qorong\'u rejim' : 'Yorug\' rejim',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Switch.adaptive(
                        value: isDark,
                        activeColor: AppColors.primary,
                        onChanged: (_) =>
                            ref.read(themeProvider.notifier).toggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Logout
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: const Text('Chiqish',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    final auth = ref.read(authServiceProvider);
                    await auth.logout();
                    ref.read(currentUserProvider.notifier).clearUser();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, _DrawerItem item, String location, bool isDark) {
    final isActive = location == item.route;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(item.icon,
            color: isActive
                ? Colors.white
                : isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
            size: 22),
        title: Text(item.title,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : isDark
                      ? AppColors.darkText
                      : AppColors.lightText,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14.5,
            )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          context.go(item.route);
        },
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;
  final String route;
  _DrawerItem(this.icon, this.title, this.route);
}
