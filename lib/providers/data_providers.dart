// lib/providers/data_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';

// Dashboard stats provider
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getOverviewStats();
});

// Courses provider
final coursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCourses();
});

// Groups provider
final groupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getGroups();
});

// Groups by course provider
final groupsByCourseProvider =
    FutureProvider.family<List<GroupModel>, int?>((ref, courseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getGroups(courseId: courseId);
});

// Students provider
final studentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStudents();
});

// Students by group provider
final studentsByGroupProvider =
    FutureProvider.family<List<StudentModel>, int?>((ref, groupId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStudents(groupId: groupId);
});

// Students by course provider
final studentsByCourseProvider =
    FutureProvider.family<List<StudentModel>, int?>((ref, courseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStudents(courseId: courseId);
});

// At-risk students provider
final atRiskStudentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAtRiskStudents();
});

// Course stats provider
final courseStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, courseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCourseStats(courseId);
});

// Group stats provider
final groupStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, groupId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getGroupStats(groupId);
});
