// lib/screens/groups/groups_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course_model.dart';
import '../../models/group_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';

// ── Providers ──────────────────────────────────────────────
final groupsProvider =
StateNotifierProvider<GroupsNotifier, AsyncValue<List<GroupModel>>>(
        (ref) => GroupsNotifier(ref.read(apiServiceProvider)));

class GroupsNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final ApiService _api;
  GroupsNotifier(this._api) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getGroups());
  }

  Future<void> add(Map<String, dynamic> data) async {
    final group = await _api.createGroup(data);
    state.whenData((list) => state = AsyncData([...list, group]));
  }

  void remove(int id) {
    state.whenData(
            (list) => state = AsyncData(list.where((g) => g.id != id).toList()));
  }

  void updateLocal(GroupModel updated) {
    state.whenData((list) => state = AsyncData(
        list.map((g) => g.id == updated.id ? updated : g).toList()));
  }
}

// Guruh o'quvchilari uchun provider
final groupStudentsProvider =
StateNotifierProvider.family<GroupStudentsNotifier, List<StudentModel>, int>(
        (ref, groupId) => GroupStudentsNotifier(groupId));

class GroupStudentsNotifier extends StateNotifier<List<StudentModel>> {
  final int groupId;
  GroupStudentsNotifier(this.groupId)
      : super(mockStudents.where((s) => s.groupId == groupId).toList());

  void add(StudentModel student) => state = [...state, student];
  void remove(int id) => state = state.where((s) => s.id != id).toList();
  void update(StudentModel updated) =>
      state = state.map((s) => s.id == updated.id ? updated : s).toList();
}

// ── Screen ─────────────────────────────────────────────────
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.groups),
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
            onPressed: () => _showAddGroupDialog(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildCourseFilter(isDark),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Xatolik: $e')),
              data: (groups) {
                final filtered = _selectedCourseId == null
                    ? groups
                    : groups.where((g) => g.courseId == _selectedCourseId).toList();
                if (filtered.isEmpty) return _buildEmpty(context);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _GroupCard(
                    group: filtered[i],
                    isDark: isDark,
                    onTap: () => _showGroupStudentsSheet(context, filtered[i]),
                    onEdit: () => _showEditGroupDialog(context, filtered[i]),
                    onDelete: () => _confirmDeleteGroup(context, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────
  Widget _buildCourseFilter(bool isDark) {
    return Container(
      height: 52,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _chip(AppLocalizations.of(context)!.all, null, isDark),
          ...mockCourses.map((c) => _chip(c.name, c.id, isDark)),
        ],
      ),
    );
  }

  Widget _chip(String label, int? courseId, bool isDark) {
    final isSelected = _selectedCourseId == courseId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCourseId = courseId),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            )),
      ),
    );
  }

  // ── Add Group ─────────────────────────────────────────────
  void _showAddGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int? selectedCourse;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.newGroup,
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.selectCourse),
                items: mockCourses
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setD(() => selectedCourse = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.groupNameHint),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && selectedCourse != null) {
                  final course = mockCourses.firstWhere((c) => c.id == selectedCourse);
                  ref.read(groupsProvider.notifier).add({
                    'name': nameCtrl.text,
                    'course_id': selectedCourse,
                    'course_name': course.name,
                  });
                  Navigator.pop(ctx);
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Group ────────────────────────────────────────────
  void _showEditGroupDialog(BuildContext context, GroupModel group) {
    final nameCtrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.editGroup,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.groupName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(groupsProvider.notifier).updateLocal(
                    group.copyWith(name: nameCtrl.text));
                Navigator.pop(ctx);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // ── Delete Group ──────────────────────────────────────────
  void _confirmDeleteGroup(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.deleteConfirm,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('"${group.name}" guruhini o\'chirasizmi?\nIchidagi o\'quvchilar ham o\'chadi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(groupsProvider.notifier).remove(group.id);
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  // ── Group Students Sheet ──────────────────────────────────
  void _showGroupStudentsSheet(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupStudentsSheet(group: group),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_rounded, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.groupNotFound, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ── Group Card ─────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = group.averageScore >= 75
        ? AppColors.success
        : group.averageScore >= 50 ? AppColors.warning : AppColors.danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(group.name[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(group.courseName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded, size: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text('${group.studentCount} o\'quvchi',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (group.atRiskCount > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.danger),
                        const SizedBox(width: 4),
                        Text('${group.atRiskCount} xavf',
                            style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded, size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 8), Text('Tahrirlash'),
                        ])),
                    const PopupMenuItem(value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Text('O\'chirish', style: TextStyle(color: AppColors.danger)),
                        ])),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
                const SizedBox(height: 4),
                Text('${group.averageScore.toStringAsFixed(1)}%',
                    style: TextStyle(color: scoreColor, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('o\'rtacha', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group Students Bottom Sheet ────────────────────────────
class _GroupStudentsSheet extends ConsumerStatefulWidget {
  final GroupModel group;
  const _GroupStudentsSheet({required this.group});

  @override
  ConsumerState<_GroupStudentsSheet> createState() => _GroupStudentsSheetState();
}

class _GroupStudentsSheetState extends ConsumerState<_GroupStudentsSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final students = ref.watch(groupStudentsProvider(widget.group.id));
    final filtered = _search.isEmpty
        ? students
        : students.where((s) => s.name.toLowerCase().contains(_search.toLowerCase())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(widget.group.name[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.group.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        Text(widget.group.courseName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  // Add button
                  GestureDetector(
                    onTap: () => _showAddStudentDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Qo\'shish', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchStudent,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                      : null,
                ),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _badge('${students.length} o\'quvchi', AppColors.primary, Icons.people_alt_rounded),
                  const SizedBox(width: 8),
                  _badge('${students.where((s) => s.isAtRisk).length} xavf ostida',
                      AppColors.danger, Icons.warning_amber_rounded),
                ],
              ),
            ),

            const Divider(height: 12),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_rounded, size: 48, color: AppColors.primary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('O\'quvchi topilmadi', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showAddStudentDialog(context),
                      icon: const Icon(Icons.person_add_rounded),
                      label: Text(AppLocalizations.of(context)!.addStudent),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _StudentRow(
                  student: filtered[i],
                  isDark: isDark,
                  onView: () {
                    Navigator.pop(context);
                    context.pushNamed('student_detail',
                        pathParameters: {'id': filtered[i].id.toString()},
                        extra: filtered[i]);
                  },
                  onEdit: () => _showEditStudentDialog(context, filtered[i]),
                  onDelete: () => _confirmDeleteStudent(context, filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Add Student ───────────────────────────────────────────
  void _showAddStudentDialog(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${widget.group.name} ga o\'quvchi qo\'shish',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl,
                decoration: InputDecoration(labelText: '${AppLocalizations.of(context)!.studentName} *')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.emailOptional)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final student = StudentModel(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: nameCtrl.text,
                  email: emailCtrl.text.isNotEmpty ? emailCtrl.text : null,
                  groupId: widget.group.id,
                  groupName: widget.group.name,
                  courseId: widget.group.courseId,
                  courseName: widget.group.courseName,
                  enrolledAt: DateTime.now(),
                );
                ref.read(groupStudentsProvider(widget.group.id).notifier).add(student);
                Navigator.pop(dCtx);
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  // ── Edit Student ──────────────────────────────────────────
  void _showEditStudentDialog(BuildContext ctx, StudentModel student) {
    final nameCtrl = TextEditingController(text: student.name);
    final emailCtrl = TextEditingController(text: student.email ?? '');

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.editStudent,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.studentName)),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(groupStudentsProvider(widget.group.id).notifier)
                    .update(student.copyWith(name: nameCtrl.text, email: emailCtrl.text));
                Navigator.pop(dCtx);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // ── Delete Student ────────────────────────────────────────
  void _confirmDeleteStudent(BuildContext ctx, StudentModel student) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.deleteConfirm,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('"${student.name}" ni o\'chirasizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(groupStudentsProvider(widget.group.id).notifier).remove(student.id);
              Navigator.pop(dCtx);
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

// ── Student Row ────────────────────────────────────────────
class _StudentRow extends StatelessWidget {
  final StudentModel student;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentRow({
    required this.student,
    required this.isDark,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final level = student.scores.level;
    final color = level == PerformanceLevel.high
        ? AppColors.highPerf
        : level == PerformanceLevel.medium ? AppColors.mediumPerf : AppColors.lowPerf;

    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: student.isAtRisk
                ? AppColors.danger.withOpacity(0.25)
                : isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Text(student.name[0],
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(student.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (student.isAtRisk)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Xavf',
                              style: TextStyle(color: AppColors.danger, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  Text('${student.scores.overall.toStringAsFixed(0)}% umumiy ball',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view',
                    child: Row(children: [
                      Icon(Icons.visibility_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8), Text('Batafsil ko\'rish'),
                    ])),
                const PopupMenuItem(value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                      SizedBox(width: 8), Text('Tahrirlash'),
                    ])),
                const PopupMenuItem(value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                      SizedBox(width: 8),
                      Text('O\'chirish', style: TextStyle(color: AppColors.danger)),
                    ])),
              ],
              onSelected: (v) {
                if (v == 'view') onView();
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}