// lib/core/utils/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/shell/shell_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/courses/courses_screen.dart';
import '../../screens/groups/groups_screen.dart';
import '../../screens/students/students_screen.dart';
import '../../screens/students/student_detail_screen.dart';
import '../../screens/prediction/prediction_screen.dart';
import '../../screens/statistics/statistics_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/daily_entry/daily_entry_screen.dart';
import '../../models/student_model.dart';
import '../../services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(authServiceProvider).isLoggedIn();
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isOnAuth) return '/login';
      if (isLoggedIn && isOnAuth) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth routes (bottom nav yo'q) ────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Shell routes (bottom nav bilan) ─────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/students',
            name: 'students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/daily-entry',
            name: 'daily_entry',
            builder: (context, state) => const DailyEntryScreen(),
          ),
          GoRoute(
            path: '/prediction',
            name: 'prediction',
            builder: (context, state) => const PredictionScreen(),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          // Courses va Groups - dashboard orqali ham kirsa bo'ladi
          GoRoute(
            path: '/courses',
            name: 'courses',
            builder: (context, state) => const CoursesScreen(),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupsScreen(),
          ),
        ],
      ),

      // ── Student detail (full screen, bottom nav yo'q) ────
      GoRoute(
        path: '/students/:id',
        name: 'student_detail',
        builder: (context, state) {
          // extra dan StudentModel olinadi
          final student = state.extra as StudentModel?;
          if (student == null) {
            // Fallback: agar extra bo'lmasa login ga qayt
            return const LoginScreen();
          }
          return StudentDetailScreen(student: student);
        },
      ),
    ],
  );
});
