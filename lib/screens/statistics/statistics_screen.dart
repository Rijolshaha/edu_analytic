// lib/screens/statistics/statistics_screen.dart
//
// Statistika sahifasi — faqat joriy o'qituvchiga tegishli ma'lumotlar
// Backend: stats/overview/, stats/groups/<id>/, stats/courses/<id>/
// Barcha endpointlar → teacher = request.user bo'yicha filter
//

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/data_providers.dart';
import '../../models/student_model.dart';
import '../../models/group_model.dart';
import '../../models/course_model.dart';
import '../../services/api_service.dart';

// ── Stats providers ────────────────────────────────────────
// Bular backend API dan olinadi → faqat teacher ga tegishli

final _overviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getOverviewStats();
});

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                gradient: AppColors.warningGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.statistics,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yangilash',
            onPressed: () {
              ref.invalidate(_overviewStatsProvider);
              ref.invalidate(studentsProvider);
              ref.invalidate(coursesProvider);
              ref.invalidate(groupsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.warning,
          indicatorWeight: 3,
          labelColor: AppColors.warning,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Umumiy'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'O\'quvchilar'),
            Tab(icon: Icon(Icons.group_rounded, size: 18), text: 'Guruhlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(isDark: isDark),
          _StudentsTab(isDark: isDark),
          _GroupsTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 1 — UMUMIY STATISTIKA
// ══════════════════════════════════════════════════════════════
class _OverviewTab extends ConsumerWidget {
  final bool isDark;
  const _OverviewTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_overviewStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorCard(error: e.toString(), isDark: isDark,
          onRetry: () => ref.invalidate(_overviewStatsProvider)),
      data: (stats) {
        final totalCourses  = stats['total_courses']  ?? 0;
        final totalGroups   = stats['total_groups']   ?? 0;
        final totalStudents = stats['total_students'] ?? 0;
        final atRisk        = stats['at_risk_students'] ?? 0;
        final avgScore      = (stats['average_score'] ?? 0.0).toDouble();
        final perfDist      = stats['performance_distribution'] as Map? ?? {};

        final high   = perfDist['High Performance']   ?? 0;
        final medium = perfDist['Medium Performance'] ?? 0;
        final low    = perfDist['Low Performance']    ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Karta qisqa statistika ───────────────────
              _SectionTitle('📊 Umumiy ko\'rsatkichlar'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _MiniStatCard('Kurslar', '$totalCourses',
                      Icons.menu_book_rounded, AppColors.primaryGradient),
                  _MiniStatCard('Guruhlar', '$totalGroups',
                      Icons.group_rounded, AppColors.infoGradient),
                  _MiniStatCard('O\'quvchilar', '$totalStudents',
                      Icons.people_alt_rounded, AppColors.successGradient),
                  _MiniStatCard('Xavf ostida', '$atRisk',
                      Icons.warning_amber_rounded, AppColors.dangerGradient),
                ],
              ),
              const SizedBox(height: 12),
              // O'rtacha ball
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.warningGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('O\'rtacha umumiy ball',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12)),
                        Text('${avgScore.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Spacer(),
                    // Mini gauge
                    SizedBox(
                      width: 56, height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: (avgScore / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 5,
                          ),
                          Text('${avgScore.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Performance taqsimoti ────────────────────
              if (high + medium + low > 0) ...[
                _SectionTitle('🤖 ML Prognoz natijalari'),
                const SizedBox(height: 12),
                _PerformanceDistCard(
                    high: high, medium: medium, low: low, isDark: isDark),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient gradient;

  const _MiniStatCard(this.label, this.value, this.icon, this.gradient);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceDistCard extends StatelessWidget {
  final int high, medium, low;
  final bool isDark;
  const _PerformanceDistCard(
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
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _perfItem(context, 'Yuqori', high, total,
                  AppColors.highPerf, Icons.emoji_events_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _perfItem(context, 'O\'rta', medium, total,
                  AppColors.mediumPerf, Icons.trending_up_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _perfItem(context, 'Past', low, total,
                  AppColors.lowPerf, Icons.warning_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (high > 0)
                    Flexible(flex: high,
                        child: Container(color: AppColors.highPerf)),
                  if (medium > 0)
                    Flexible(flex: medium,
                        child: Container(color: AppColors.mediumPerf)),
                  if (low > 0)
                    Flexible(flex: low,
                        child: Container(color: AppColors.lowPerf)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfItem(BuildContext context, String label, int count, int total,
      Color color, IconData icon) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text('$label ($pct%)',
              style: TextStyle(color: color, fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 2 — O'QUVCHILAR (faqat teacher ga tegishlilar)
// ══════════════════════════════════════════════════════════════
class _StudentsTab extends ConsumerWidget {
  final bool isDark;
  const _StudentsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorCard(error: e.toString(), isDark: isDark,
          onRetry: () => ref.invalidate(studentsProvider)),
      data: (students) {
        if (students.isEmpty) {
          return _EmptyState(
            icon: Icons.people_alt_rounded,
            message: 'Hali o\'quvchilar yo\'q',
            subtitle: 'Avval guruh va o\'quvchi qo\'shing',
          );
        }

        final displayStudents =
            students.length > 20 ? students.sublist(0, 20) : students;
        final high   = students.where((s) => s.scores.level == PerformanceLevel.high).length;
        final medium = students.where((s) => s.scores.level == PerformanceLevel.medium).length;
        final low    = students.where((s) => s.scores.level == PerformanceLevel.low).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Daraja taqsimoti ─────────────────────────
              _SectionTitle('🎯 Daraja taqsimoti (${students.length} ta)'),
              const SizedBox(height: 12),
              _buildRiskPieChart(context, isDark, high, medium, low),
              const SizedBox(height: 24),

              // ── Ball taqsimoti grafigi ────────────────────
              _SectionTitle(students.length > 20
                  ? '📊 Ball taqsimoti (dastlabki 20 ta)'
                  : '📊 Ball taqsimoti'),
              const SizedBox(height: 12),
              _buildBarChart(context, isDark, displayStudents),
              const SizedBox(height: 24),

              // ── O'rtacha ko'rsatkichlar ───────────────────
              _SectionTitle('📈 O\'rtacha ko\'rsatkichlar'),
              const SizedBox(height: 12),
              _buildAverageScores(context, isDark, students),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskPieChart(BuildContext context, bool isDark,
      int high, int medium, int low) {
    final total = high + medium + low;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDeco(isDark),
        child: const Center(child: Text('Ma\'lumot yo\'q')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Row(
        children: [
          SizedBox(
            width: 140, height: 140,
            child: PieChart(
              PieChartData(
                sections: [
                  if (high > 0)
                    PieChartSectionData(
                      color: AppColors.highPerf,
                      value: high.toDouble(),
                      title: '$high',
                      radius: 55,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  if (medium > 0)
                    PieChartSectionData(
                      color: AppColors.mediumPerf,
                      value: medium.toDouble(),
                      title: '$medium',
                      radius: 55,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  if (low > 0)
                    PieChartSectionData(
                      color: AppColors.lowPerf,
                      value: low.toDouble(),
                      title: '$low',
                      radius: 55,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 25,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PieLegend(AppColors.highPerf, 'Yuqori (≥70%)', high, total),
                const SizedBox(height: 10),
                _PieLegend(AppColors.mediumPerf, 'O\'rta (40-69%)', medium, total),
                const SizedBox(height: 10),
                _PieLegend(AppColors.lowPerf, 'Past (<40%)', low, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      BuildContext context, bool isDark, List<StudentModel> students) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex >= students.length) return null;
                return BarTooltipItem(
                  '${students[groupIndex].name.split(' ')[0]}\n${rod.toY.toStringAsFixed(0)}%',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= students.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      students[i].name.split(' ')[0],
                      style: TextStyle(
                          fontSize: 8,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                    style: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ),
            ),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (v) => FlLine(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              strokeWidth: 1,
            ),
          ),
          barGroups: students.asMap().entries.map((e) {
            final score = e.value.scores.overall;
            final color = score >= 70
                ? AppColors.highPerf
                : score >= 40
                    ? AppColors.mediumPerf
                    : AppColors.lowPerf;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: score,
                  color: color,
                  width: students.length > 10 ? 12 : 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAverageScores(
      BuildContext context, bool isDark, List<StudentModel> students) {
    if (students.isEmpty) return const SizedBox();

    double avgAtt = 0, avgHw = 0, avgQuiz = 0, avgExam = 0;
    for (final s in students) {
      avgAtt  += s.scores.attendance;
      avgHw   += s.scores.homework;
      avgQuiz += s.scores.quiz;
      avgExam += s.scores.exam;
    }
    final n = students.length.toDouble();
    avgAtt  /= n; avgHw  /= n;
    avgQuiz /= n; avgExam /= n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          _AvgRow(context, 'Davomat', avgAtt, AppColors.info, isDark),
          const SizedBox(height: 10),
          _AvgRow(context, 'Uy vazifasi', avgHw, AppColors.success, isDark),
          const SizedBox(height: 10),
          _AvgRow(context, 'Quiz', avgQuiz, AppColors.warning, isDark),
          const SizedBox(height: 10),
          _AvgRow(context, 'Imtihon', avgExam, AppColors.danger, isDark),
        ],
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count, total;
  const _PieLegend(this.color, this.label, this.count, this.total);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('$count ta ($pct%)',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _AvgRow(BuildContext context, String label, double avg,
    Color color, bool isDark) {
  return Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (avg / 100).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text('${avg.toStringAsFixed(1)}%',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color)),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
//  TAB 3 — GURUHLAR (backend stats/groups/<id>/ orqali)
// ══════════════════════════════════════════════════════════════
class _GroupsTab extends ConsumerWidget {
  final bool isDark;
  const _GroupsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync  = ref.watch(groupsProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorCard(error: e.toString(), isDark: isDark,
          onRetry: () => ref.invalidate(groupsProvider)),
      data: (groups) {
        if (groups.isEmpty) {
          return _EmptyState(
            icon: Icons.group_rounded,
            message: 'Hali guruhlar yo\'q',
            subtitle: 'Kurs va guruh qo\'shing',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kurslar statistikasi
              coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('📚 Kurslar bo\'yicha'),
                      const SizedBox(height: 12),
                      _buildCourseLineChart(context, isDark, courses),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
              ),

              _SectionTitle('👥 Guruhlar bo\'yicha (${groups.length} ta)'),
              const SizedBox(height: 12),

              ...groups.map((group) => _GroupStatCard(
                    group: group,
                    isDark: isDark,
                  )),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseLineChart(
      BuildContext context, bool isDark, List<CourseModel> courses) {
    if (courses.isEmpty) return const SizedBox();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kurslar o\'rtacha bali',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 100,
                barGroups: courses.asMap().entries.map((e) {
                  final score = e.value.averageScore;
                  final color = score >= 75
                      ? AppColors.success
                      : score >= 50
                          ? AppColors.warning
                          : AppColors.danger;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: score,
                        color: color,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= courses.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(courses[i].name,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}',
                          style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    strokeWidth: 1,
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

// ── Guruh statistika karta ─────────────────────────────────
class _GroupStatCard extends ConsumerWidget {
  final GroupModel group;
  final bool isDark;

  const _GroupStatCard({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupStatsAsync = ref.watch(groupStatsProvider(group.id));
    final scoreColor = group.averageScore >= 75
        ? AppColors.success
        : group.averageScore >= 50
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(group.name[0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${group.courseName} — ${group.name}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Icon(Icons.people_alt_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          const SizedBox(width: 4),
                          Text('${group.studentCount} o\'quvchi',
                              style: Theme.of(context).textTheme.bodySmall),
                          if (group.atRiskCount > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.warning_amber_rounded,
                                size: 12, color: AppColors.danger),
                            const SizedBox(width: 4),
                            Text('${group.atRiskCount} xavf',
                                style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${group.averageScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text('o\'rtacha',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (group.averageScore / 100).clamp(0.0, 1.0),
                backgroundColor: scoreColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(scoreColor),
                minHeight: 8,
              ),
            ),
          ),
          // API dan kelgan batafsil statistika
          groupStatsAsync.when(
            data: (stats) {
              final students = stats['students'] as List? ?? [];
              if (students.isEmpty) return const SizedBox();
              return _GroupDetailStats(
                  students: students, isDark: isDark);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (e, _) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _GroupDetailStats extends StatelessWidget {
  final List students;
  final bool isDark;
  const _GroupDetailStats({required this.students, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final high   = students.where((s) => s['level'] == 'High Performance').length;
    final medium = students.where((s) => s['level'] == 'Medium Performance').length;
    final low    = students.where((s) => s['level'] == 'Low Performance').length;
    final total  = students.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.15)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SmallStat('🏆 Yuqori', high, AppColors.highPerf),
          _SmallStat('📈 O\'rta', medium, AppColors.mediumPerf),
          _SmallStat('⚠️ Past', low, AppColors.lowPerf),
          _SmallStat('👥 Jami', total, AppColors.primary),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SmallStat(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  YORDAMCHI WIDGETLAR
// ══════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorCard(
      {required this.error, required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text('Ma\'lumot yuklanmadi',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Qayta urinish'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, subtitle;
  const _EmptyState(
      {required this.icon,
      required this.message,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

BoxDecoration _cardDeco(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.darkCard : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2)),
    ],
  );
}
