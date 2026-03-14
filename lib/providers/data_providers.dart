// lib/providers/data_providers.dart
//
// Bu fayl barcha umumiy providerlarda birlik ta'minlaydi.
// Courses, Groups, Students uchun StateNotifierProvider screen
// fayllaridan import qilinadi — alohida FutureProvider emas,
// chunki bir xil nomli provider ikki joyda bo'lsa state
// sync bo'lmaydi.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';

// ── Re-export screen providerlar ──────────────────────────
// Import orqali dashboard va boshqa sahifalar bir xil
// StateNotifierProvider dan foydalanadi.
export '../screens/courses/courses_screen.dart' show coursesProvider, CoursesNotifier;
export '../screens/groups/groups_screen.dart'   show groupsProvider, GroupsNotifier, groupStudentsProvider;
export '../screens/students/students_screen.dart' show studentsProvider, StudentsNotifier;

// ── Dashboard stats provider ──────────────────────────────
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getOverviewStats();
});

// ── Groups by course ──────────────────────────────────────
final groupsByCourseProvider =
    FutureProvider.family<List<GroupModel>, int?>((ref, courseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getGroups(courseId: courseId);
});

// ── Students by group ─────────────────────────────────────
final studentsByGroupProvider =
    FutureProvider.family<List<StudentModel>, int?>((ref, groupId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStudents(groupId: groupId);
});

// ── Students by course ────────────────────────────────────
final studentsByCourseProvider =
    FutureProvider.family<List<StudentModel>, int?>((ref, courseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStudents(courseId: courseId);
});

// ── At-risk students ──────────────────────────────────────
final atRiskStudentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAtRiskStudents();
});

// ── Course stats ──────────────────────────────────────────
final courseStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, courseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCourseStats(courseId);
});

// ── Group stats ───────────────────────────────────────────
final groupStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, groupId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getGroupStats(groupId);
});
