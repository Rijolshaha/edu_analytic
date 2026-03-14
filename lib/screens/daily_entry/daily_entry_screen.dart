// lib/screens/daily_entry/daily_entry_screen.dart
// ✅ TUZATILGAN:
//   1. Ball validatsiyasi: score > maxScore → maxScore ga clamp, score < 0 → 0 ga clamp
//   2. _save() ichida ham validatsiya: xato bo'lsa snackbar chiqadi
//   3. Muvaffaqiyatli saqlanganda barcha tegishli providerlar invalidate qilinadi
//      (studentsProvider, dashboardStatsProvider, atRiskStudentsProvider, groupStudentsProvider)
//   4. Teacher-specific data: API JWT orqali avtomatik filtrlaydi

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../models/student_model.dart';
import '../../providers/data_providers.dart';
import '../../services/api_service.dart';
import '../groups/groups_screen.dart' show groupsProvider, groupStudentsProvider;

// ── Providers ──────────────────────────────────────────────
final _selectedGroupProvider = StateProvider<GroupModel?>((ref) => null);
final _selectedDateProvider  = StateProvider<DateTime>((ref) => DateTime.now());

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

// ✅ Score validatsiyasi uchun helper — manfiy va maxScore dan katta bo'lmasin
String _clampScore(String input, double maxScore) {
  if (input.isEmpty) return '0';
  final val = double.tryParse(input) ?? 0.0;
  if (val < 0)        return '0';
  if (val > maxScore) return maxScore.toStringAsFixed(maxScore == maxScore.roundToDouble() ? 0 : 1);
  return input;
}

// ── Barcha tegishli providerlari yangilash ─────────────────
void _refreshAllProviders(WidgetRef ref, int groupId) {
  ref.invalidate(studentsProvider);
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(atRiskStudentsProvider);
  ref.invalidate(groupStudentsProvider(groupId));
  ref.invalidate(groupStatsProvider(groupId));
}

// ══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class DailyEntryScreen extends ConsumerStatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  ConsumerState<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends ConsumerState<DailyEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final groupsAsync   = ref.watch(groupsProvider);
    final selectedGroup = ref.watch(_selectedGroupProvider);
    final selectedDate  = ref.watch(_selectedDateProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF3F4FF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Kunlik Kiritish', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.how_to_reg_rounded, size: 20), text: 'Davomat'),
            Tab(icon: Icon(Icons.assignment_turned_in_rounded, size: 20), text: 'Uy vazifasi'),
            Tab(icon: Icon(Icons.quiz_rounded, size: 20), text: 'Quiz/Imtihon'),
          ],
        ),
      ),
      body: Column(
        children: [
          _GroupDateBar(
            groupsAsync: groupsAsync,
            selectedGroup: selectedGroup,
            selectedDate: selectedDate,
            isDark: isDark,
            onGroupChanged: (g) => ref.read(_selectedGroupProvider.notifier).state = g,
            onDateChanged:  (d) => ref.read(_selectedDateProvider.notifier).state  = d,
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: selectedGroup == null
                ? _SelectGroupHint(isDark: isDark)
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _AttendanceTab(group: selectedGroup),
                      _HomeworkTab(group: selectedGroup),
                      _QuizTab(group: selectedGroup),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  GURUH + SANA BAR
// ══════════════════════════════════════════════════════════════
class _GroupDateBar extends StatelessWidget {
  final AsyncValue<List<GroupModel>> groupsAsync;
  final GroupModel? selectedGroup;
  final DateTime selectedDate;
  final bool isDark;
  final ValueChanged<GroupModel?> onGroupChanged;
  final ValueChanged<DateTime> onDateChanged;

  const _GroupDateBar({
    required this.groupsAsync,
    required this.selectedGroup,
    required this.selectedDate,
    required this.isDark,
    required this.onGroupChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today   = DateTime.now();
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day   == today.day;

    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: groupsAsync.when(
              loading: () => Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (e, _) => const Text('Xatolik', style: TextStyle(color: AppColors.danger)),
              data: (groups) => DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selectedGroup != null
                            ? AppColors.primary.withOpacity(0.5)
                            : isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: DropdownButton<GroupModel>(
                    value: selectedGroup,
                    hint: const Row(children: [
                      Icon(Icons.group_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Guruh tanlang', style: TextStyle(fontSize: 13)),
                    ]),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: groups.map((g) => DropdownMenuItem(
                      value: g,
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(g.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(g.courseName, style: const TextStyle(fontSize: 10, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        )),
                      ]),
                    )).toList(),
                    onChanged: onGroupChanged,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '${selectedDate.day.toString().padLeft(2,'0')}/${selectedDate.month.toString().padLeft(2,'0')}/${selectedDate.year}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Bugun', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
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
//  GURUH TANLANMAGAN HINT
// ══════════════════════════════════════════════════════════════
class _SelectGroupHint extends StatelessWidget {
  final bool isDark;
  const _SelectGroupHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 20),
          Text('Guruh tanlang', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Yuqoridagi ochiladigan menyudan guruh tanlang, so\'ng sana va ma\'lumot kiriting.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ...[
            ('1', 'Guruh tanlang',         Icons.group_rounded,         AppColors.primary),
            ('2', 'Sana tanlang',           Icons.calendar_month_rounded, AppColors.info),
            ('3', 'Ma\'lumot kiriting',     Icons.edit_rounded,           AppColors.success),
            ('4', 'Saqlash tugmasini bosing', Icons.check_circle_rounded, AppColors.warning),
          ].map((step) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: (step.$4 as Color).withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text(step.$1 as String, style: TextStyle(color: step.$4 as Color, fontWeight: FontWeight.w700, fontSize: 12))),
              ),
              const SizedBox(width: 10),
              Icon(step.$3 as IconData, size: 16, color: step.$4 as Color),
              const SizedBox(width: 6),
              Text(step.$2 as String,
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
            ]),
          )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DAVOMAT TAB
// ══════════════════════════════════════════════════════════════
class _AttendanceTab extends ConsumerStatefulWidget {
  final GroupModel group;
  const _AttendanceTab({required this.group});

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  final Map<int, bool> _present = {};
  final Map<int, bool> _excused = {};
  List<StudentModel> _students = [];
  int  _lessonNumber = 1;
  bool _loading = false;

  void _init(List<StudentModel> students) {
    _students = students;
    for (final s in students) {
      _present.putIfAbsent(s.id, () => true);
      _excused.putIfAbsent(s.id, () => false);
    }
  }

  Future<void> _save() async {
    if (_students.isEmpty) return;
    setState(() => _loading = true);
    final date = ref.read(_selectedDateProvider);
    try {
      final result = await ref.read(apiServiceProvider).bulkAttendance({
        'group_id':      widget.group.id,
        'date':          _fmt(date),
        'lesson_number': _lessonNumber,
        'attendances': _students.map((s) => {
          'student_id': s.id,
          'is_present': _present[s.id] ?? true,
          'is_excused': _excused[s.id] ?? false,
          'note': '',
        }).toList(),
      });
      if (mounted) {
        _showSuccess(result['message'] ?? '✅ Davomat saqlandi');
        // ✅ Barcha tegishli providerlarni yangilash
        _refreshAllProviders(ref, widget.group.id);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg.replaceAll('Exception: ', ''), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(groupStudentsProvider(widget.group.id));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text('O\'quvchilar yuklanmadi: $e'),
        ],
      )),
      data: (students) {
        _init(students);
        final presentCount = _present.values.where((v) => v).length;
        final absentCount  = students.length - presentCount;

        return Column(
          children: [
            // ── Statistika va dars raqami ──────────────────
            Container(
              color: isDark ? AppColors.darkSurface : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  _StatusBadge('${students.length} ta', AppColors.primary, Icons.people_alt_rounded),
                  const SizedBox(width: 8),
                  _StatusBadge('$presentCount keldi', AppColors.success, Icons.check_circle_rounded),
                  const SizedBox(width: 8),
                  _StatusBadge('$absentCount kelmadi', AppColors.danger, Icons.cancel_rounded),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Dars:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _lessonNumber,
                            isDense: true,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                            items: List.generate(6, (i) => i + 1).map((n) =>
                                DropdownMenuItem(value: n, child: Text(' $n'))).toList(),
                            onChanged: (v) => setState(() => _lessonNumber = v ?? 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Expanded(child: _QuickBtn(
                    label: '✓ Barchasi keldi', color: AppColors.success,
                    onTap: () => setState(() { for (final s in students) _present[s.id] = true; }),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickBtn(
                    label: '✗ Barchasi kelmadi', color: AppColors.danger,
                    onTap: () => setState(() { for (final s in students) _present[s.id] = false; }),
                  )),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  final isPresent = _present[s.id] ?? true;
                  final isExcused = _excused[s.id] ?? false;
                  final color = isPresent ? AppColors.success : isExcused ? AppColors.warning : AppColors.danger;

                  return _StudentAttCard(
                    student: s,
                    isPresent: isPresent,
                    isExcused: isExcused,
                    color: color,
                    isDark: isDark,
                    onToggle: () => setState(() {
                      _present[s.id] = !isPresent;
                      if (isPresent) _excused[s.id] = false;
                    }),
                    onExcusedToggle: () => setState(() => _excused[s.id] = !isExcused),
                  );
                },
              ),
            ),
            _SaveButton(loading: _loading, label: 'Davomatni saqlash', gradient: AppColors.successGradient, onTap: _save),
          ],
        );
      },
    );
  }
}

class _StudentAttCard extends StatelessWidget {
  final StudentModel student;
  final bool isPresent, isExcused, isDark;
  final Color color;
  final VoidCallback onToggle, onExcusedToggle;

  const _StudentAttCard({
    required this.student, required this.isPresent, required this.isExcused,
    required this.isDark, required this.color,
    required this.onToggle, required this.onExcusedToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.15),
            child: Text(student.name[0], style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (!isPresent)
                  GestureDetector(
                    onTap: onExcusedToggle,
                    child: Row(children: [
                      Icon(
                        isExcused ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 13,
                        color: isExcused ? AppColors.warning : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(isExcused ? 'Sababli' : 'Sababsiz (bosing)',
                          style: TextStyle(fontSize: 11, color: isExcused ? AppColors.warning : AppColors.lightTextSecondary, fontWeight: FontWeight.w500)),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72, height: 34,
              decoration: BoxDecoration(
                gradient: isPresent ? AppColors.successGradient : AppColors.dangerGradient,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Center(child: Text(isPresent ? '✓ Keldi' : '✗ Kelm.',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  UY VAZIFASI TAB
// ══════════════════════════════════════════════════════════════
class _HomeworkTab extends ConsumerStatefulWidget {
  final GroupModel group;
  const _HomeworkTab({required this.group});

  @override
  ConsumerState<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends ConsumerState<_HomeworkTab> {
  final Map<int, TextEditingController> _ctrl = {};
  final Map<int, bool> _submitted = {};
  final _titleCtrl = TextEditingController();
  List<StudentModel> _students = [];
  double _maxScore = 10;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _init(List<StudentModel> s) {
    _students = s;
    for (final st in s) {
      _ctrl.putIfAbsent(st.id, () => TextEditingController(text: '0'));
      _submitted.putIfAbsent(st.id, () => true);
    }
  }

  // ✅ maxScore o'zgarganda barcha balllarni qayta clamp qilish
  void _onMaxScoreChanged(double newMax) {
    setState(() {
      _maxScore = newMax;
      for (final entry in _ctrl.entries) {
        final current = double.tryParse(entry.value.text) ?? 0.0;
        if (current > newMax) {
          entry.value.text = newMax.toStringAsFixed(newMax == newMax.roundToDouble() ? 0 : 1);
        }
      }
    });
  }

  // ✅ Score kiritishda validatsiya
  void _onScoreChanged(int studentId, String value) {
    final clamped = _clampScore(value, _maxScore);
    if (clamped != value) {
      final ctrl = _ctrl[studentId]!;
      ctrl.text = clamped;
      ctrl.selection = TextSelection.fromPosition(TextPosition(offset: clamped.length));
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { _showWarn('Uy vazifasi nomini kiriting!'); return; }
    if (_students.isEmpty) return;

    // ✅ Saqlashdan oldin ham validatsiya
    final hasInvalid = _ctrl.entries.any((e) {
      final val = double.tryParse(e.value.text) ?? 0.0;
      return val < 0 || val > _maxScore;
    });
    if (hasInvalid) { _showWarn('Ball 0 dan ${ _maxScore.toStringAsFixed(0)} gacha bo\'lishi kerak!'); return; }

    setState(() => _loading = true);
    final date = ref.read(_selectedDateProvider);
    try {
      final result = await ref.read(apiServiceProvider).bulkHomework({
        'group_id':  widget.group.id,
        'date':      _fmt(date),
        'title':     _titleCtrl.text.trim(),
        'max_score': _maxScore,
        'students':  _students.map((s) => {
          'student_id': s.id,
          'score':     double.tryParse(_ctrl[s.id]?.text ?? '0') ?? 0.0,
          'submitted': _submitted[s.id] ?? true,
          'note': '',
        }).toList(),
      });
      if (mounted) {
        _showSuccess(result['message'] ?? '✅ Saqlandi');
        _titleCtrl.clear();
        // ✅ Barcha tegishli providerlarni yangilash
        _refreshAllProviders(ref, widget.group.id);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(_snack(m, AppColors.success, Icons.check_circle_rounded));
  void _showWarn(String m)    => ScaffoldMessenger.of(context).showSnackBar(_snack(m, AppColors.warning, Icons.warning_rounded));
  void _showError(String m)   => ScaffoldMessenger.of(context).showSnackBar(_snack(m.replaceAll('Exception: ', ''), AppColors.danger, Icons.error_rounded));

  SnackBar _snack(String m, Color c, IconData icon) => SnackBar(
    content: Row(children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text(m, maxLines: 2, overflow: TextOverflow.ellipsis))]),
    backgroundColor: c,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(groupStudentsProvider(widget.group.id));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (students) {
        _init(students);
        return Column(
          children: [
            Container(
              color: isDark ? AppColors.darkSurface : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Uy vazifasi nomi *',
                        prefixIcon: const Icon(Icons.assignment_rounded, color: AppColors.success),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Text('Maks.', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      // ✅ onChanged → _onMaxScoreChanged: mavjud balllarni ham yangilaydi
                      DropdownButton<double>(
                        value: _maxScore,
                        isDense: true,
                        items: [5.0, 10.0, 20.0, 50.0, 100.0].map((v) =>
                            DropdownMenuItem(value: v, child: Text(v.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                        onChanged: (v) { if (v != null) _onMaxScoreChanged(v); },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s    = students[i];
                  final isSub = _submitted[s.id] ?? true;
                  final score = double.tryParse(_ctrl[s.id]?.text ?? '0') ?? 0;
                  final pct   = _maxScore > 0 ? score / _maxScore : 0.0;
                  // ✅ Xato ball → qizil border
                  final isInvalid = score < 0 || score > _maxScore;
                  final color = isInvalid ? AppColors.danger : pct >= 0.7 ? AppColors.success : pct >= 0.4 ? AppColors.warning : AppColors.danger;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isInvalid ? AppColors.danger.withOpacity(0.6) : (isSub ? color.withOpacity(0.3) : AppColors.danger.withOpacity(0.25))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.info.withOpacity(0.15),
                          child: Text(s.name[0], style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (isSub && _maxScore > 0)
                                LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  backgroundColor: color.withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 3,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            _submitted[s.id] = !isSub;
                            if (!isSub) _ctrl[s.id]?.text = '0';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSub ? AppColors.success.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isSub ? '✓' : '✗',
                                style: TextStyle(fontSize: 14, color: isSub ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 72,
                          child: TextField(
                            controller: _ctrl[s.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            enabled: isSub,
                            textAlign: TextAlign.center,
                            // ✅ Validatsiya — maxScore dan katta yoki manfiy bo'lmasin
                            onChanged: (v) => _onScoreChanged(s.id, v),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              suffix: Text('/${_maxScore.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isInvalid ? AppColors.danger : color.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isInvalid ? AppColors.danger : color, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.danger, width: 2),
                              ),
                            ),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSub ? (isInvalid ? AppColors.danger : color) : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _SaveButton(loading: _loading, label: 'Uy vazifalarini saqlash', gradient: AppColors.successGradient, onTap: _save),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  QUIZ / IMTIHON TAB
// ══════════════════════════════════════════════════════════════
class _QuizTab extends ConsumerStatefulWidget {
  final GroupModel group;
  const _QuizTab({required this.group});

  @override
  ConsumerState<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<_QuizTab> {
  final Map<int, TextEditingController> _ctrl = {};
  final _topicCtrl = TextEditingController();
  List<StudentModel> _students = [];
  String _type = 'quiz';
  double _maxScore = 20;
  bool _loading = false;

  static const _types = [
    {'v': 'quiz',      'l': '📝 Quiz',      'g': AppColors.primaryGradient},
    {'v': 'classwork', 'l': '📖 Sinf ishi', 'g': AppColors.infoGradient},
    {'v': 'exam',      'l': '📋 Imtihon',   'g': AppColors.dangerGradient},
  ];

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _init(List<StudentModel> s) {
    _students = s;
    for (final st in s) {
      _ctrl.putIfAbsent(st.id, () => TextEditingController(text: '0'));
    }
  }

  // ✅ maxScore o'zgarganda barcha balllarni qayta clamp qilish
  void _onMaxScoreChanged(double newMax) {
    setState(() {
      _maxScore = newMax;
      for (final entry in _ctrl.entries) {
        final current = double.tryParse(entry.value.text) ?? 0.0;
        if (current > newMax) {
          entry.value.text = newMax.toStringAsFixed(newMax == newMax.roundToDouble() ? 0 : 1);
        }
      }
    });
  }

  // ✅ Score kiritishda validatsiya
  void _onScoreChanged(int studentId, String value) {
    final clamped = _clampScore(value, _maxScore);
    if (clamped != value) {
      final ctrl = _ctrl[studentId]!;
      ctrl.text = clamped;
      ctrl.selection = TextSelection.fromPosition(TextPosition(offset: clamped.length));
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_topicCtrl.text.trim().isEmpty) { _showWarn('Mavzu nomini kiriting!'); return; }
    if (_students.isEmpty) return;

    // ✅ Saqlashdan oldin validatsiya
    final hasInvalid = _ctrl.entries.any((e) {
      final val = double.tryParse(e.value.text) ?? 0.0;
      return val < 0 || val > _maxScore;
    });
    if (hasInvalid) { _showWarn('Ball 0 dan ${_maxScore.toStringAsFixed(0)} gacha bo\'lishi kerak!'); return; }

    setState(() => _loading = true);
    final date = ref.read(_selectedDateProvider);
    try {
      final result = await ref.read(apiServiceProvider).bulkQuiz({
        'group_id':  widget.group.id,
        'date':      _fmt(date),
        'quiz_type': _type,
        'topic':     _topicCtrl.text.trim(),
        'max_score': _maxScore,
        'students':  _students.map((s) => {
          'student_id': s.id,
          'score':     double.tryParse(_ctrl[s.id]?.text ?? '0') ?? 0.0,
          'note': '',
        }).toList(),
      });
      if (mounted) {
        _showSuccess(result['message'] ?? '✅ Saqlandi');
        _topicCtrl.clear();
        // ✅ Barcha tegishli providerlarni yangilash
        _refreshAllProviders(ref, widget.group.id);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(_snack(m, AppColors.success, Icons.check_circle_rounded));
  void _showWarn(String m)    => ScaffoldMessenger.of(context).showSnackBar(_snack(m, AppColors.warning, Icons.warning_rounded));
  void _showError(String m)   => ScaffoldMessenger.of(context).showSnackBar(_snack(m.replaceAll('Exception: ', ''), AppColors.danger, Icons.error_rounded));

  SnackBar _snack(String m, Color c, IconData icon) => SnackBar(
    content: Row(children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text(m, maxLines: 2, overflow: TextOverflow.ellipsis))]),
    backgroundColor: c,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(groupStudentsProvider(widget.group.id));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (students) {
        _init(students);
        return Column(
          children: [
            Container(
              color: isDark ? AppColors.darkSurface : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tur chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _types.map((t) {
                        final isSel = _type == t['v'];
                        return GestureDetector(
                          onTap: () => setState(() => _type = t['v'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSel ? (t['g'] as LinearGradient) : null,
                              color: isSel ? null : (isDark ? AppColors.darkCard : AppColors.lightBg),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                              boxShadow: isSel ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))] : [],
                            ),
                            child: Text(t['l'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSel ? Colors.white : null)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicCtrl,
                          decoration: InputDecoration(
                            labelText: 'Mavzu *',
                            prefixIcon: const Icon(Icons.topic_rounded, color: AppColors.warning),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          Text('Maks.', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          // ✅ onChanged → _onMaxScoreChanged
                          DropdownButton<double>(
                            value: _maxScore,
                            isDense: true,
                            items: [10.0, 20.0, 50.0, 100.0].map((v) =>
                                DropdownMenuItem(value: v, child: Text(v.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                            onChanged: (v) { if (v != null) _onMaxScoreChanged(v); },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s    = students[i];
                  final score = double.tryParse(_ctrl[s.id]?.text ?? '0') ?? 0;
                  final pct   = _maxScore > 0 ? score / _maxScore : 0.0;
                  final isInvalid = score < 0 || score > _maxScore;
                  final color = isInvalid ? AppColors.danger : pct >= 0.7 ? AppColors.success : pct >= 0.4 ? AppColors.warning : AppColors.danger;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isInvalid ? AppColors.danger.withOpacity(0.6) : color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(s.name[0], style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                backgroundColor: color.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 72,
                          child: TextField(
                            controller: _ctrl[s.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            textAlign: TextAlign.center,
                            // ✅ Validatsiya — maxScore dan katta yoki manfiy bo'lmasin
                            onChanged: (v) => _onScoreChanged(s.id, v),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              suffix: Text('/${_maxScore.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isInvalid ? AppColors.danger : color.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isInvalid ? AppColors.danger : color, width: 2),
                              ),
                            ),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isInvalid ? AppColors.danger : color),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _SaveButton(loading: _loading, label: 'Natijalarni saqlash', gradient: AppColors.warningGradient, onTap: _save),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  UMUMIY YORDAMCHI WIDGETLAR
// ══════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool loading;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _SaveButton({required this.loading, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: loading ? null : gradient,
              color: loading ? Colors.grey.shade400 : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
