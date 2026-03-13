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
import '../../models/student_model.dart';
import '../../services/auth_service.dart';

// Provider to check if user is logged in
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.isLoggedIn();
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(authServiceProvider).isLoggedIn();
      final isOnLogin = state.matchedLocation == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isOnLogin) {
        return '/login';
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isOnLogin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth - bottom nav yo'q
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

      // Shell - bottom nav bor
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
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
          GoRoute(
            path: '/students',
            name: 'students',
            builder: (context, state) => const StudentsScreen(),
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
        ],
      ),

      // Student detail - bottom nav yo'q (full screen)
      GoRoute(
        path: '/students/:id',
        name: 'student_detail',
        builder: (context, state) {
          final student = state.extra as StudentModel;
          return StudentDetailScreen(student: student);
        },
      ),
    ],
  );
});
