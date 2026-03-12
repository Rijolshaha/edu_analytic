// lib/screens/courses/courses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course_model.dart';
import '../../services/api_service.dart';

final coursesProvider =
StateNotifierProvider<CoursesNotifier, AsyncValue<List<CourseModel>>>(
        (ref) => CoursesNotifier(ref.read(apiServiceProvider)));

class CoursesNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final ApiService _api;
  CoursesNotifier(this._api) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getCourses());
  }

  Future<void> add(Map<String, dynamic> data) async {
    final course = await _api.createCourse(data);
    state.whenData((list) => state = AsyncData([...list, course]));
  }

  Future<void> remove(int id) async {
    await _api.deleteCourse(id);
    state.whenData((list) =>
    state = AsyncData(list.where((c) => c.id != id).toList()));
  }
}

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.courses),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => _showAddDialog(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (courses) => courses.isEmpty
            ? _buildEmpty(context)
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: courses.length,
          itemBuilder: (ctx, i) =>
              _CourseCard(course: courses[i], isDark: isDark),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:  Text(AppLocalizations.of(context)!.newCourse,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.courseName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'Fan (math, physics...)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Tavsif'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(coursesProvider.notifier).add({
                  'name': nameCtrl.text,
                  'subject': subjectCtrl.text,
                  'description': descCtrl.text,
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64,
              color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noData,
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  final CourseModel course;
  final bool isDark;

  const _CourseCard({required this.course, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreColor = course.averageScore >= 75
        ? AppColors.success
        : course.averageScore >= 50
        ? AppColors.warning
        : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      if (course.description.isNotEmpty)
                        Text(course.description,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Text('O\'chirish',
                              style: TextStyle(color: AppColors.danger)),
                        ])),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') {
                      ref
                          .read(coursesProvider.notifier)
                          .remove(course.id);
                    }
                  },
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStat(context, Icons.group_rounded,
                    '${course.groupCount}', 'Guruh'),
                const SizedBox(width: 16),
                _buildStat(context, Icons.people_alt_rounded,
                    '${course.studentCount}', 'O\'quvchi'),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${course.averageScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    Text('O\'rtacha ball',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: course.averageScore / 100,
                backgroundColor: scoreColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(scoreColor),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}