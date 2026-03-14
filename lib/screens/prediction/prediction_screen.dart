// lib/screens/prediction/prediction_screen.dart
//
// ML Prognoz sahifasi — faqat joriy o'qituvchiga tegishli o'quvchilar
// Backend: PredictView va BatchPredictView → group__course__teacher=request.user
//
// Arxitektura:
//   Tab 1 — Guruh tanlash + Umumiy prognoz (batch API)
//   Tab 2 — Natijalar ro'yxati

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../models/prediction_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../groups/groups_screen.dart' show groupsProvider;

// ── State providers ────────────────────────────────────────
final _predGroupProvider   = StateProvider<GroupModel?>((ref) => null);
final _predResultsProvider = StateProvider<List<PredictionResult>>((ref) => []);
final _predLoadingProvider = StateProvider<bool>((ref) => false);
final _predErrorProvider   = StateProvider<String?>((ref) => null);

// ══════════════════════════════════════════════════════════════
class PredictionScreen extends ConsumerStatefulWidget {
  const PredictionScreen({super.key});

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Batch predict: guruh o'quvchilari uchun ──────────────
  Future<void> _runPrediction() async {
    final group = ref.read(_predGroupProvider);

    // Guruh tanlanmagan bo'lsa → barcha o'quvchilar uchun
    ref.read(_predLoadingProvider.notifier).state = true;
    ref.read(_predErrorProvider.notifier).state = null;
    ref.read(_predResultsProvider.notifier).state = [];

    try {
      final api = ref.read(apiServiceProvider);

      // 1. O'quvchilar ID larini olish
      final students = group != null
          ? await api.getStudents(groupId: group.id)
          : await api.getStudents();

      if (students.isEmpty) {
        ref.read(_predErrorProvider.notifier).state =
            'O\'quvchilar topilmadi. Avval guruhga o\'quvchi qo\'shing.';
        return;
      }

      final studentIds = students.map((s) => s.id).toList();

      // 2. Batch predict API — POST /api/v1/predict/batch/
      final results = await api.batchPredict(studentIds);

      if (results.isEmpty) {
        // Fallback: local hisoblash (agar batch API ham ishlamasa)
        final fallbackResults = students.map((s) =>
          PredictionResult.fromScores(
            studentId: s.id,
            studentName: s.name,
            attendance: s.scores.attendance,
            homework: s.scores.homework,
            quiz: s.scores.quiz,
            exam: s.scores.exam,
          ),
        ).toList();
        ref.read(_predResultsProvider.notifier).state = fallbackResults;
      } else {
        ref.read(_predResultsProvider.notifier).state = results;
      }

      // Natijalar tabiga o'tish
      _tabCtrl.animateTo(1);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      ref.read(_predErrorProvider.notifier).state = msg;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Xatolik: $msg'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } finally {
      if (mounted) {
        ref.read(_predLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(_predLoadingProvider);
    final results   = ref.watch(_predResultsProvider);
    final error     = ref.watch(_predErrorProvider);
    final selGroup  = ref.watch(_predGroupProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF3F4FF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('ML Prognoz',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            const Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Prognoz'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 18),
                  const SizedBox(width: 4),
                  const Text('Natijalar'),
                  if (results.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${results.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PredictTab(
            isDark: isDark,
            isLoading: isLoading,
            results: results,
            error: error,
            selectedGroup: selGroup,
            onRun: _runPrediction,
            onGroupChanged: (g) =>
                ref.read(_predGroupProvider.notifier).state = g,
          ),
          _ResultsTab(isDark: isDark, results: results),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 1 — PROGNOZ
// ══════════════════════════════════════════════════════════════
class _PredictTab extends ConsumerWidget {
  final bool isDark, isLoading;
  final List<PredictionResult> results;
  final String? error;
  final GroupModel? selectedGroup;
  final VoidCallback onRun;
  final ValueChanged<GroupModel?> onGroupChanged;

  const _PredictTab({
    required this.isDark,
    required this.isLoading,
    required this.results,
    required this.error,
    required this.selectedGroup,
    required this.onRun,
    required this.onGroupChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final high   = results.where((p) => p.level == PredictionLevel.high).length;
    final medium = results.where((p) => p.level == PredictionLevel.medium).length;
    final low    = results.where((p) => p.level == PredictionLevel.low).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Guruh tanlash ────────────────────────────────
          _SectionLabel('Guruh tanlang', Icons.group_rounded),
          const SizedBox(height: 10),
          groupsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Guruhlar yuklanmadi: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (groups) => _GroupSelector(
              groups: groups,
              selected: selectedGroup,
              isDark: isDark,
              onChanged: onGroupChanged,
            ),
          ),
          const SizedBox(height: 20),

          // ── Prognoz banner ───────────────────────────────
          _PredictBanner(
            isDark: isDark,
            isLoading: isLoading,
            selectedGroup: selectedGroup,
            onRun: onRun,
          ),

          // ── Xatolik ──────────────────────────────────────
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(error!,
                          style: const TextStyle(color: AppColors.danger))),
                ],
              ),
            ),
          ],

          // ── Natija statistikasi ───────────────────────────
          if (results.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionLabel('Natija taqsimoti', Icons.pie_chart_rounded),
            const SizedBox(height: 12),
            _StatsRow(high: high, medium: medium, low: low),
            const SizedBox(height: 16),
            _DistributionBar(
                high: high, medium: medium, low: low, isDark: isDark),
            const SizedBox(height: 20),
            // Pie chart
            _PredictionPieChart(
                high: high, medium: medium, low: low, isDark: isDark),
          ],

          // ── Loading indikator ─────────────────────────────
          if (isLoading) ...[
            const SizedBox(height: 24),
            _LoadingCard(isDark: isDark),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Guruh selector ─────────────────────────────────────────
class _GroupSelector extends StatelessWidget {
  final List<GroupModel> groups;
  final GroupModel? selected;
  final bool isDark;
  final ValueChanged<GroupModel?> onChanged;

  const _GroupSelector({
    required this.groups,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "Barchasi" chip
          _GroupChip(
            label: '🌐 Barchasi',
            subtitle: '${groups.fold(0, (s, g) => s + g.studentCount)} ta',
            isSelected: selected == null,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          ...groups.map((g) => _GroupChip(
                label: '${g.name}',
                subtitle: '${g.courseName} · ${g.studentCount} ta',
                isSelected: selected?.id == g.id,
                isDark: isDark,
                onTap: () => onChanged(g),
              )),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label, subtitle;
  final bool isSelected, isDark;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected ? Colors.white : null)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary))),
          ],
        ),
      ),
    );
  }
}

// ── Predict banner ────────────────────────────────────────
class _PredictBanner extends StatelessWidget {
  final bool isDark, isLoading;
  final GroupModel? selectedGroup;
  final VoidCallback onRun;

  const _PredictBanner({
    required this.isDark,
    required this.isLoading,
    required this.selectedGroup,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final target = selectedGroup != null
        ? '${selectedGroup!.name} guruhi'
        : 'Barcha o\'quvchilar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_rounded, color: Colors.white, size: 44),
          const SizedBox(height: 12),
          const Text('Machine Learning Prognoz',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '$target uchun o\'zlashtirish\ndarajasini prognoz qiling',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Run button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onRun,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 10),
                            Text('Prognoz qilinmoqda...',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text('$target — Prognoz qilish',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int high, medium, low;
  const _StatsRow({required this.high, required this.medium, required this.low});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _LevelCard('Yuqori', high, AppColors.successGradient, Icons.emoji_events_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _LevelCard('O\'rta', medium, AppColors.warningGradient, Icons.trending_up_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _LevelCard('Past', low, AppColors.dangerGradient, Icons.warning_rounded)),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String label;
  final int count;
  final LinearGradient gradient;
  final IconData icon;
  const _LevelCard(this.label, this.count, this.gradient, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Distribution bar ──────────────────────────────────────
class _DistributionBar extends StatelessWidget {
  final int high, medium, low;
  final bool isDark;
  const _DistributionBar(
      {required this.high,
      required this.medium,
      required this.low,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = high + medium + low;
    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foizli taqsimot',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  if (high > 0)
                    Flexible(
                      flex: high,
                      child: Container(
                        color: AppColors.highPerf,
                        child: Center(
                          child: Text(
                            '${(high / total * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  if (medium > 0)
                    Flexible(
                      flex: medium,
                      child: Container(
                        color: AppColors.mediumPerf,
                        child: Center(
                          child: Text(
                            '${(medium / total * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  if (low > 0)
                    Flexible(
                      flex: low,
                      child: Container(
                        color: AppColors.lowPerf,
                        child: Center(
                          child: Text(
                            '${(low / total * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Legend(AppColors.highPerf, 'Yuqori', high),
              _Legend(AppColors.mediumPerf, 'O\'rta', medium),
              _Legend(AppColors.lowPerf, 'Past', low),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend(this.color, this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$label: $count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Pie chart ────────────────────────────────────────────
class _PredictionPieChart extends StatelessWidget {
  final int high, medium, low;
  final bool isDark;
  const _PredictionPieChart(
      {required this.high,
      required this.medium,
      required this.low,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = high + medium + low;
    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Text('O\'quvchilar daraja taqsimoti',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: [
                  if (high > 0)
                    PieChartSectionData(
                      color: AppColors.highPerf,
                      value: high.toDouble(),
                      title: '$high\n${(high / total * 100).toStringAsFixed(0)}%',
                      radius: 72,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  if (medium > 0)
                    PieChartSectionData(
                      color: AppColors.mediumPerf,
                      value: medium.toDouble(),
                      title: '$medium\n${(medium / total * 100).toStringAsFixed(0)}%',
                      radius: 72,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  if (low > 0)
                    PieChartSectionData(
                      color: AppColors.lowPerf,
                      value: low.toDouble(),
                      title: '$low\n${(low / total * 100).toStringAsFixed(0)}%',
                      radius: 72,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading card ──────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  final bool isDark;
  const _LoadingCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 14),
          Text('ML model tahlil qilmoqda...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Barcha o\'quvchilar uchun hisoblanyapti',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 2 — NATIJALAR
// ══════════════════════════════════════════════════════════════
class _ResultsTab extends StatefulWidget {
  final bool isDark;
  final List<PredictionResult> results;

  const _ResultsTab({required this.isDark, required this.results});

  @override
  State<_ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<_ResultsTab> {
  String _filter = 'all'; // all | high | medium | low
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_rounded,
                size: 64, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Hali prognoz qilinmagan',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('"Prognoz" tabiga boring va guruh tanlang',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    // Filter
    var filtered = widget.results.where((p) {
      final matchFilter = _filter == 'all' ||
          (_filter == 'high' && p.level == PredictionLevel.high) ||
          (_filter == 'medium' && p.level == PredictionLevel.medium) ||
          (_filter == 'low' && p.level == PredictionLevel.low);
      final matchSearch = _search.isEmpty ||
          p.studentName.toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    // Sort: past daraja avval
    filtered.sort((a, b) => a.predictedScore.compareTo(b.predictedScore));

    return Column(
      children: [
        // Search + filter
        Container(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              // Search
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'O\'quvchi nomini qidiring...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip('all', 'Barchasi (${widget.results.length})',
                        _filter, (v) => setState(() => _filter = v),
                        widget.isDark),
                    _FilterChip('high',
                        '🏆 Yuqori (${widget.results.where((p) => p.level == PredictionLevel.high).length})',
                        _filter, (v) => setState(() => _filter = v),
                        widget.isDark),
                    _FilterChip('medium',
                        '📈 O\'rta (${widget.results.where((p) => p.level == PredictionLevel.medium).length})',
                        _filter, (v) => setState(() => _filter = v),
                        widget.isDark),
                    _FilterChip('low',
                        '⚠️ Past (${widget.results.where((p) => p.level == PredictionLevel.low).length})',
                        _filter, (v) => setState(() => _filter = v),
                        widget.isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('Natija topilmadi',
                      style: Theme.of(context).textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _ResultCard(
                    prediction: filtered[i],
                    isDark: widget.isDark,
                    rank: i + 1,
                  ),
                ),
        ),
      ],
    );
  }
}

Widget _FilterChip(
    String value, String label, String current,
    ValueChanged<String> onChanged, bool isDark) {
  final isSelected = current == value;
  final color = value == 'high'
      ? AppColors.highPerf
      : value == 'medium'
          ? AppColors.mediumPerf
          : value == 'low'
              ? AppColors.lowPerf
              : AppColors.primary;

  return GestureDetector(
    onTap: () => onChanged(value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? color
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary))),
    ),
  );
}

// ── Result card ───────────────────────────────────────────
class _ResultCard extends StatefulWidget {
  final PredictionResult prediction;
  final bool isDark;
  final int rank;
  const _ResultCard(
      {required this.prediction, required this.isDark, required this.rank});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final isHigh   = p.level == PredictionLevel.high;
    final isMedium = p.level == PredictionLevel.medium;
    final color    = isHigh
        ? AppColors.highPerf
        : isMedium
            ? AppColors.mediumPerf
            : AppColors.lowPerf;
    final initial  = p.studentName.isNotEmpty ? p.studentName[0] : '?';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            // Main row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${widget.rank}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(initial,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.studentName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(p.levelLabel,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                            Text('Xavf: ${p.riskPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${p.predictedScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: color.withOpacity(0.6),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded — recommendation
            if (_expanded) ...[
              Divider(
                  height: 1,
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
              // Progress bars
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  children: [
                    _ScoreBar(context, 'Prognoz ball',
                        p.predictedScore / 100, color),
                    const SizedBox(height: 4),
                    _ScoreBar(context, 'Xavf darajasi',
                        p.riskPercentage / 100, AppColors.danger),
                  ],
                ),
              ),
              // Recommendation
              if (p.recommendation.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          // Faqat birinchi qatorni ko'rsatamiz
                          p.recommendation.split('\n').first,
                          style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ScoreBar(
      BuildContext context, String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}
