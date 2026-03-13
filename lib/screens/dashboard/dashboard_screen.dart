// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course_model.dart';
import '../../models/group_model.dart';
import '../../models/student_model.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../providers/data_providers.dart';
import '../../providers/notification_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    // Fetch real data from API
    final statsAsync = ref.watch(dashboardStatsProvider);
    final atRiskAsync = ref.watch(atRiskStudentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    // Get unread notification count
    final unreadCount = notificationsAsync.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user?.name ?? l.teacher, isDark, unreadCount,
              notificationsAsync),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGreeting(context, user?.name ?? l.teacher, isDark),
                const SizedBox(height: 24),
                // Stats from API
                statsAsync.when(
                  data: (stats) => _buildStatsGridFromApi(context, stats, l),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      _buildErrorCard(context, e.toString(), isDark),
                ),
                const SizedBox(height: 28),
                _buildSectionTitle(context, l.atRiskTitle, isDark),
                const SizedBox(height: 14),
                // At-risk students from API
                atRiskAsync.when(
                  data: (students) =>
                      _buildAtRiskListFromApi(context, students, isDark),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      _buildErrorCard(context, e.toString(), isDark),
                ),
                const SizedBox(height: 28),
                _buildSectionTitle(context, l.coursePerformanceTitle, isDark),
                const SizedBox(height: 14),
                // Courses from API
                coursesAsync.when(
                  data: (courses) => _buildCoursePerformanceFromApi(
                      context, courses, isDark, l),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      _buildErrorCard(context, e.toString(), isDark),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, String name, bool isDark,
      int unreadCount, AsyncValue<List<NotificationModel>> notificationsAsync) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: const SizedBox(),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.analytics_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('EduAnalytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  )),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () =>
                  _showNotificationsPanel(context, notificationsAsync, isDark),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showNotificationsPanel(BuildContext context,
      AsyncValue<List<NotificationModel>> notificationsAsync, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('Bildirishnomalar',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Bildirishnomalar yo\'q')),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        leading: Icon(
                          notification.type == NotificationType.atRisk
                              ? Icons.warning
                              : Icons.info,
                          color: notification.type == NotificationType.atRisk
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                        title: Text(notification.title),
                        subtitle: Text(notification.message),
                        trailing: Text(
                          _formatDate(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Xatolik: $e')),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min oldin';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} soat oldin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} kun oldin';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildGreeting(BuildContext context, String name, bool isDark) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(22),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.greetingPrefix,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(l.greetingSubtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGridFromApi(
      BuildContext context, Map<String, dynamic> stats, AppLocalizations l) {
    final totalCourses = stats['total_courses'] ?? 0;
    final totalGroups = stats['total_groups'] ?? 0;
    final totalStudents = stats['total_students'] ?? 0;
    final atRisk = stats['at_risk_students'] ?? 0;
    final avgScore = (stats['average_score'] ?? 0.0).toDouble();

    final statsCards = [
      _StatCard(l.courses, totalCourses.toString(), Icons.menu_book_rounded,
          AppColors.infoGradient, '/courses'),
      _StatCard(l.groups, totalGroups.toString(), Icons.group_rounded,
          AppColors.successGradient, '/groups'),
      _StatCard(l.students, totalStudents.toString(), Icons.people_alt_rounded,
          AppColors.primaryGradient, '/students'),
      _StatCard(l.atRiskStudents, atRisk.toString(),
          Icons.warning_amber_rounded, AppColors.dangerGradient, '/students'),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.65,
          ),
          itemCount: statsCards.length,
          itemBuilder: (context, i) => _buildStatCard(context, statsCards[i]),
        ),
        const SizedBox(height: 14),
        _buildWideStatCard(
          context,
          l.averageScore,
          '${avgScore.toStringAsFixed(1)}%',
          Icons.bar_chart_rounded,
          AppColors.warningGradient,
          '/statistics',
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, _StatCard s) {
    return GestureDetector(
      onTap: () => context.go(s.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: s.gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(s.icon, color: Colors.white, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1)),
                const SizedBox(height: 2),
                Text(s.label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideStatCard(BuildContext context, String label, String value,
      IconData icon, LinearGradient gradient, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700));
  }

  Widget _buildAtRiskListFromApi(
      BuildContext context, List<StudentModel> students, bool isDark) {
    final l = AppLocalizations.of(context)!;
    if (students.isEmpty) {
      return _buildEmptyState(context, isDark, l.noData);
    }
    return Column(
      children:
          students.map((s) => _buildAtRiskTile(context, s, isDark)).toList(),
    );
  }

  Widget _buildAtRiskTile(BuildContext context, StudentModel s, bool isDark) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.danger.withOpacity(0.15),
            child: Text(s.name.isNotEmpty ? s.name[0] : '?',
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('${s.courseName ?? ''} · ${s.groupName ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${s.scores.overall.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(height: 4),
              Text(l.riskLabel,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursePerformanceFromApi(BuildContext context,
      List<CourseModel> courses, bool isDark, AppLocalizations l) {
    if (courses.isEmpty) {
      return _buildEmptyState(context, isDark, l.noData);
    }
    return Column(
      children: courses.map((course) {
        final pct = course.averageScore / 100;
        final color = course.averageScore >= 75
            ? AppColors.success
            : course.averageScore >= 50
                ? AppColors.warning
                : AppColors.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                            '${course.groupCount} ${l.groups} · ${course.studentCount} ${l.studentsCount}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text('${course.averageScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.length > 50 ? '${error.substring(0, 50)}...' : error,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(msg,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                )),
      ),
    );
  }
}

class _StatCard {
  final String label, value, route;
  final IconData icon;
  final LinearGradient gradient;
  _StatCard(this.label, this.value, this.icon, this.gradient, this.route);
}
