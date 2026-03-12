// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile card
            _buildProfileCard(context, user?.name ?? AppLocalizations.of(context)!.teacher, user?.email ?? '', isDark),
            const SizedBox(height: 24),

            // Appearance section
            _buildSectionLabel(context, AppLocalizations.of(context)!.appearance),
            const SizedBox(height: 12),
            _buildSettingCard(context, isDark, [
              _SettingTile(
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: AppColors.primary,
                title: isDark ? AppLocalizations.of(context)!.darkMode : AppLocalizations.of(context)!.lightMode,
                subtitle: AppLocalizations.of(context)!.themeSubtitle,
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: AppColors.primary,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Language section
            _buildSectionLabel(context, AppLocalizations.of(context)!.language),
            const SizedBox(height: 12),
            _buildSettingCard(context, isDark, [
              _SettingTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.info,
                title: "O'zbek",
                subtitle: "O'zbek tili",
                trailing: Radio<String>(
                  value: 'uz',
                  groupValue: locale.languageCode,
                  activeColor: AppColors.primary,
                  onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
                ),
              ),
              _SettingTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.secondary,
                title: 'English',
                subtitle: 'English language',
                trailing: Radio<String>(
                  value: 'en',
                  groupValue: locale.languageCode,
                  activeColor: AppColors.primary,
                  onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
                ),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 20),

            // About section
            _buildSectionLabel(context, AppLocalizations.of(context)!.aboutApp),
            const SizedBox(height: 12),
            _buildSettingCard(context, isDark, [
              _SettingTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.warning,
                title: AppLocalizations.of(context)!.version,
                subtitle: 'EduAnalytics v1.0.0',
                isLast: true,
              ),
            ]),
            const SizedBox(height: 20),

            // Logout
            _buildSectionLabel(context, AppLocalizations.of(context)!.account),
            const SizedBox(height: 12),
            _buildLogoutButton(context, ref),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String name, String email, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'T',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(AppLocalizations.of(context)!.teacher,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          )),
    );
  }

  Widget _buildSettingCard(BuildContext context, bool isDark, List<_SettingTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: tiles.asMap().entries.map((e) {
          final tile = e.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tile.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tile.icon, color: tile.iconColor, size: 20),
                ),
                title: Text(tile.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Text(tile.subtitle, style: Theme.of(context).textTheme.bodySmall),
                trailing: tile.trailing,
              ),
              if (!tile.isLast)
                Divider(
                  height: 1,
                  indent: 66,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(AppLocalizations.of(context)!.logoutTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              content: Text(AppLocalizations.of(context)!.logoutConfirm),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context)!.cancel)),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLocalizations.of(context)!.logout)),
              ],
            ),
          );
          if (confirmed == true) {
            final auth = ref.read(authServiceProvider);
            await auth.logout();
            ref.read(currentUserProvider.notifier).clearUser();
            if (context.mounted) context.go('/login');
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}

class _SettingTile {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isLast;

  _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isLast = false,
  });
}