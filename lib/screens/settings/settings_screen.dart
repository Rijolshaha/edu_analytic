// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

final _profileProvider = FutureProvider<UserModel?>((ref) async {
  try {
    final api = ref.read(apiServiceProvider);
    return await api.getMe();
  } catch (_) {
    return ref.read(authServiceProvider).getUser();
  }
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = ref.watch(themeProvider) == ThemeMode.dark;
    final locale      = ref.watch(localeProvider);
    final stateUser   = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(_profileProvider);
    final user        = stateUser ?? profileAsync.asData?.value;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF3F4FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                user: user,
                isDark: isDark,
                isLoading: stateUser == null && profileAsync.isLoading,
              ),
            ),
            leading: const SizedBox.shrink(),
            leadingWidth: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null) ...[
                    _UserInfoCard(user: user, isDark: isDark),
                    const SizedBox(height: 24),
                  ],

                  // ── Ko'rinish ──────────────────────────────
                  _SectionLabel(
                    label: AppLocalizations.of(context)!.appearance,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    tiles: [
                      _SettingRow(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: const Color(0xFF6366F1),
                        // ✅ FIX: dark modeda matn oq, yorug'da qora
                        title: isDark
                            ? AppLocalizations.of(context)!.darkMode
                            : AppLocalizations.of(context)!.lightMode,
                        subtitle: AppLocalizations.of(context)!.themeSubtitle,
                        isDark: isDark,
                        trailing: Switch.adaptive(
                          value: isDark,
                          activeColor: AppColors.primary,
                          onChanged: (_) =>
                              ref.read(themeProvider.notifier).toggleTheme(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Til ────────────────────────────────────
                  _SectionLabel(
                    label: AppLocalizations.of(context)!.language,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    tiles: [
                      _SettingRow(
                        icon: Icons.language_rounded,
                        iconColor: AppColors.info,
                        title: "O'zbek tili",
                        subtitle: 'Uz',
                        isDark: isDark,
                        trailing: Radio<String>(
                          value: 'uz',
                          groupValue: locale.languageCode,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              ref.read(localeProvider.notifier).setLocale(v!),
                        ),
                      ),
                      _SettingRow(
                        icon: Icons.language_rounded,
                        iconColor: AppColors.secondary,
                        title: 'English',
                        subtitle: 'En',
                        isDark: isDark,
                        isLast: true,
                        trailing: Radio<String>(
                          value: 'en',
                          groupValue: locale.languageCode,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              ref.read(localeProvider.notifier).setLocale(v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Ilova haqida ───────────────────────────
                  _AboutAppCard(isDark: isDark),
                  const SizedBox(height: 20),

                  // ── Hisob ──────────────────────────────────
                  _SectionLabel(
                    label: AppLocalizations.of(context)!.account,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _LogoutButton(isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ABOUT APP CARD + DIALOG
// ══════════════════════════════════════════════════════════════
class _AboutAppCard extends StatelessWidget {
  final bool isDark;
  const _AboutAppCard({required this.isDark});

  void _showAboutDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        // ✅ FIX: isDark dan kelib chiqib matn ranglarini belgilash
        final textColor    = isDark ? Colors.white : const Color(0xFF1A1A2E);
        final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.aboutApp,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textColor, // ✅
                        )),
                    const SizedBox(height: 2),
                    Text('EduAnalytics v1.0.0',
                        style: TextStyle(fontSize: 12, color: subTextColor)), // ✅
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "• O'qituvchilar uchun kurs, guruh va o'quvchilarni boshqarish",
                style: TextStyle(fontSize: 13, color: textColor), // ✅
              ),
              const SizedBox(height: 6),
              Text(
                '• Davomat, uy vazifasi, quiz va imtihon natijalari asosida tahlil',
                style: TextStyle(fontSize: 13, color: textColor), // ✅
              ),
              const SizedBox(height: 6),
              Text(
                "• ML asosida xavf ostidagi o'quvchilarni prognoz qilish",
                style: TextStyle(fontSize: 13, color: textColor), // ✅
              ),
              const SizedBox(height: 12),
              Text(
                'Backend: eduanalytics-backend (Django REST, ML)',
                style: TextStyle(fontSize: 12, color: subTextColor), // ✅
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showAboutDialog(context),
      child: _SettingsCard(
        isDark: isDark,
        tiles: [
          _SettingRow(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.warning,
            title: l.aboutApp,
            subtitle: 'EduAnalytics v1.0.0 · ML prognoz va statistika',
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PROFILE HEADER
// ══════════════════════════════════════════════════════════════
class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final bool isDark;
  final bool isLoading;

  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '...';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'T';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.settings,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.teacher,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF818CF8), Color(0xFFA855F7)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: isLoading
                        ? const Center(child: SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                        : Center(child: Text(initials,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLoading
                            ? Container(width: 140, height: 18,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4)))
                            : Text(user?.name ?? "O'qituvchi",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        isLoading
                            ? Container(width: 100, height: 13,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4)))
                            : Text(user?.email ?? '',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (user?.subject != null && user!.subject!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(user!.subject!,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  USER INFO CARD
// ══════════════════════════════════════════════════════════════
class _UserInfoCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  const _UserInfoCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Profil ma'lumotlari",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    // ✅ FIX: dark modeda oq
                    color: isDark ? Colors.white : AppColors.lightText,
                  )),
          const SizedBox(height: 14),
          _infoRow(context, Icons.person_rounded, 'Ism Familiya', user.name, isDark),
          _infoRow(context, Icons.alternate_email_rounded, 'Username', user.username ?? '—', isDark),
          _infoRow(context, Icons.email_rounded, 'Email', user.email, isDark),
          if (user.phone != null && user.phone!.isNotEmpty)
            _infoRow(context, Icons.phone_rounded, 'Telefon', user.phone!, isDark),
          if (user.subject != null && user.subject!.isNotEmpty)
            _infoRow(context, Icons.school_rounded, 'Fan', user.subject!, isDark, isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, bool isDark,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          )),
                  Text(value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            // ✅ FIX: dark modeda oq
                            color: isDark ? Colors.white : AppColors.lightText,
                          ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Divider(height: 1, indent: 48, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<_SettingRow> tiles;
  const _SettingsCard({required this.isDark, required this.tiles});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: dark modeda matn oq, yorug'da to'q
    final titleColor    = isDark ? Colors.white          : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: tiles.asMap().entries.map((e) {
          final tile = e.value;
          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: tile.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tile.icon, color: tile.iconColor, size: 20),
                ),
                title: Text(
                  tile.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: titleColor, // ✅ explicit rang
                  ),
                ),
                subtitle: Text(
                  tile.subtitle,
                  style: TextStyle(
                    color: subtitleColor, // ✅ explicit rang
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: tile.trailing,
              ),
              if (!tile.isLast)
                Divider(
                  height: 1,
                  indent: 70,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingRow {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isLast;
  final bool isDark;

  _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
    this.isLast = false,
  });
}

// ══════════════════════════════════════════════════════════════
//  LOGOUT BUTTON
// ══════════════════════════════════════════════════════════════
class _LogoutButton extends ConsumerWidget {
  final bool isDark;
  const _LogoutButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () => _showLogoutDialog(context, ref),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
        ),
        title: const Text('Chiqish',
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
        subtitle: Text('Tizimdan chiqish',
            style: TextStyle(color: AppColors.danger.withOpacity(0.6), fontSize: 11)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.danger.withOpacity(0.5)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.logoutTitle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).logout();
              ref.read(currentUserProvider.notifier).clearUser();
              if (context.mounted) context.go('/login');
            },
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }
}
