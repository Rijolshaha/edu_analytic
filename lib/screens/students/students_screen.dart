// lib/screens/students/students_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course_model.dart';
import '../../models/group_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../courses/courses_screen.dart' show coursesProvider;
import '../groups/groups_screen.dart' show groupsProvider;

final studentsProvider =
    StateNotifierProvider<StudentsNotifier, AsyncValue<List<StudentModel>>>(
        (ref) => StudentsNotifier(ref.read(apiServiceProvider)));

class StudentsNotifier extends StateNotifier<AsyncValue<List<StudentModel>>> {
  final ApiService _api;
  StudentsNotifier(this._api) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getStudents());
  }

  Future<void> add(Map<String, dynamic> data) async {
    try {
      final student = await _api.createStudent(data);
      state.whenData((list) => state = AsyncData([...list, student]));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> remove(int id) async {
    try {
      await _api.deleteStudent(id);
      state.whenData(
          (list) => state = AsyncData(list.where((s) => s.id != id).toList()));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateLocal(StudentModel updated) async {
    try {
      await _api.updateStudent(updated.id, {
        'name': updated.name,
        'email': updated.email,
      });
      state.whenData((list) => state =
          AsyncData(list.map((s) => s.id == updated.id ? updated : s).toList()));
    } catch (e) {
      // Local update saqlab qolamiz (API xatolik bo'lsa)
      state.whenData((list) => state =
          AsyncData(list.map((s) => s.id == updated.id ? updated : s).toList()));
    }
  }
}

final studentSearchProvider = StateProvider<String>((ref) => '');
final studentFilterProvider = StateProvider<int?>((ref) => null);

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final search = ref.watch(studentSearchProvider);
    final filterCourse = ref.watch(studentFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.students),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => _showAddDialog(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(studentSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchStudent,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(studentSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildChip(context, AppLocalizations.of(context)!.all, null,
                    filterCourse, isDark),
                ...coursesAsync.when(
                  data: (courses) => courses.map((c) =>
                      _buildChip(context, c.name, c.id, filterCourse, isDark)),
                  loading: () => [],
                  error: (_, __) => [],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Xatolik: $e')),
              data: (students) {
                var filtered = students;
                if (filterCourse != null) {
                  filtered = filtered
                      .where((s) => s.courseId == filterCourse)
                      .toList();
                }
                if (search.isNotEmpty) {
                  filtered = filtered
                      .where((s) =>
                          s.name.toLowerCase().contains(search.toLowerCase()))
                      .toList();
                }
                if (filtered.isEmpty) return _buildEmpty(context);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _StudentTile(
                    student: filtered[i],
                    isDark: isDark,
                    onTap: () => context.pushNamed('student_detail',
                        pathParameters: {'id': filtered[i].id.toString()},
                        extra: filtered[i]),
                    onEdit: () => _showEditDialog(context, filtered[i]),
                    onDelete: () => _confirmDelete(context, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, int? courseId,
      int? current, bool isDark) {
    final isSelected = current == courseId;
    return GestureDetector(
      onTap: () => ref.read(studentFilterProvider.notifier).state = courseId,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : isDark
                  ? AppColors.darkCard
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.darkText
                      : AppColors.lightText,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            )),
      ),
    );
  }

  // ── Add Student Dialog ─────────────────────────────────────
  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    int? selectedCourseId;
    int? selectedGroupId;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref2, _) {
          final coursesAsync = ref2.watch(coursesProvider);
          final groupsAsync = ref2.watch(groupsProvider);
          return StatefulBuilder(
            builder: (ctx, setD) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(AppLocalizations.of(context)!.newStudent,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ism
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText:
                            '${AppLocalizations.of(context)!.studentName} *',
                        prefixIcon:
                            const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Email
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.emailOptional,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Kurs
                    coursesAsync.when(
                      data: (courses) => DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText:
                              '${AppLocalizations.of(context)!.selectCourse} *',
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                        ),
                        value: selectedCourseId,
                        items: courses
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setD(() {
                          selectedCourseId = v;
                          selectedGroupId = null;
                        }),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Xatolik: $e'),
                    ),
                    const SizedBox(height: 12),
                    // Guruh
                    groupsAsync.when(
                      data: (groups) {
                        final filtered = selectedCourseId == null
                            ? <GroupModel>[]
                            : groups
                                .where(
                                    (g) => g.courseId == selectedCourseId)
                                .toList();
                        // agar tanlangan guruh filtrlangan listda yo'q bo'lsa reset
                        if (selectedGroupId != null &&
                            !filtered.any((g) => g.id == selectedGroupId)) {
                          selectedGroupId = null;
                        }
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: selectedCourseId == null
                                ? AppLocalizations.of(context)!
                                    .selectGroupFirst
                                : '${AppLocalizations.of(context)!.selectGroup} *',
                            prefixIcon: const Icon(Icons.group_rounded),
                          ),
                          value: selectedGroupId,
                          items: filtered
                              .map((g) => DropdownMenuItem(
                                  value: g.id, child: Text(g.name)))
                              .toList(),
                          onChanged: selectedCourseId == null
                              ? null
                              : (v) => setD(() => selectedGroupId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Xatolik: $e'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.cancel)),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty &&
                        selectedCourseId != null &&
                        selectedGroupId != null) {
                      ref.read(studentsProvider.notifier).add({
                        'name': nameCtrl.text,
                        'email': emailCtrl.text.isNotEmpty
                            ? emailCtrl.text
                            : null,
                        'group': selectedGroupId,
                      });
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.requiredFields),
                          backgroundColor: const Color(0xFFEF4444),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.add),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Edit Student Dialog ────────────────────────────────────
  void _showEditDialog(BuildContext context, StudentModel student) {
    final nameCtrl = TextEditingController(text: student.name);
    final emailCtrl = TextEditingController(text: student.email ?? '');
    int? selectedCourseId = student.courseId;
    int? selectedGroupId = student.groupId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.editStudent,
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ism familiya',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (ctx, ref2, _) {
                    final coursesAsync = ref2.watch(coursesProvider);
                    final groupsAsync = ref2.watch(groupsProvider);
                    return Column(
                      children: [
                        // Kurs
                        coursesAsync.when(
                          data: (courses) => DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Kurs',
                              prefixIcon: Icon(Icons.menu_book_rounded),
                            ),
                            value: selectedCourseId,
                            items: courses
                                .map((c) => DropdownMenuItem(
                                    value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) => setD(() {
                              selectedCourseId = v;
                              selectedGroupId = null;
                            }),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Xatolik: $e'),
                        ),
                        const SizedBox(height: 12),
                        // Guruh
                        groupsAsync.when(
                          data: (groups) {
                            final filtered = selectedCourseId == null
                                ? <GroupModel>[]
                                : groups
                                    .where((g) =>
                                        g.courseId == selectedCourseId)
                                    .toList();
                            return DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.group,
                                prefixIcon: const Icon(Icons.group_rounded),
                              ),
                              value: filtered.any((g) => g.id == selectedGroupId)
                                  ? selectedGroupId
                                  : null,
                              items: filtered
                                  .map((g) => DropdownMenuItem(
                                      value: g.id, child: Text(g.name)))
                                  .toList(),
                              onChanged: (v) => setD(() => selectedGroupId = v),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Xatolik: $e'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  await ref.read(studentsProvider.notifier).updateLocal(
                        student.copyWith(
                          name: nameCtrl.text,
                          email: emailCtrl.text,
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm ─────────────────────────────────────────
  void _confirmDelete(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.deleteConfirm,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('"${student.name}" ni o\'chirasizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(studentsProvider.notifier).remove(student.id);
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.delete),
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
          Icon(Icons.people_alt_rounded,
              size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.studentNotFound,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.person_add_rounded),
            label: Text(AppLocalizations.of(context)!.addStudent),
          ),
        ],
      ),
    );
  }
}

// ── Student Tile ───────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final StudentModel student;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentTile({
    required this.student,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final level = student.scores.level;
    final color = level == PerformanceLevel.high
        ? AppColors.highPerf
        : level == PerformanceLevel.medium
            ? AppColors.mediumPerf
            : AppColors.lowPerf;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: student.isAtRisk
                ? AppColors.danger.withOpacity(0.3)
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Text(student.name[0],
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(student.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (student.isAtRisk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Xavf',
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  Text('${student.courseName} · ${student.groupName}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _score('Davomat', student.scores.attendance),
                      const SizedBox(width: 10),
                      _score('Quiz', student.scores.quiz),
                      const SizedBox(width: 10),
                      _score('Imtihon', student.scores.exam),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Score + menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Tahrirlash'),
                        ])),
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
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
                Text('${student.scores.overall.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _score(String label, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${val.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: AppColors.lightTextSecondary)),
      ],
    );
  }
}
