// lib/screens/statistics/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/data_providers.dart';
import '../../models/student_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(studentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.statistics)),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (students) => coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Xatolik: $e')),
          data: (courses) => groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Xatolik: $e')),
            data: (groups) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context,
                      AppLocalizations.of(context)!.studentPerformance),
                  const SizedBox(height: 14),
                  _buildStudentPerformanceChart(context, isDark, students),
                  const SizedBox(height: 28),
                  _sectionTitle(
                      context, AppLocalizations.of(context)!.coursePerformance),
                  const SizedBox(height: 14),
                  _buildCourseChart(context, isDark, courses),
                  const SizedBox(height: 28),
                  _sectionTitle(
                      context, AppLocalizations.of(context)!.groupStatistics),
                  const SizedBox(height: 14),
                  _buildGroupStats(context, isDark, groups),
                  const SizedBox(height: 28),
                  _sectionTitle(
                      context, AppLocalizations.of(context)!.riskDistribution),
                  const SizedBox(height: 14),
                  _buildRiskPieChart(context, isDark, students),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700));
  }

  Widget _buildStudentPerformanceChart(
      BuildContext context, bool isDark, List students) {
    // Ko'p talabalar bo'lsa chartni o'qish qiyin - max 15 ta ko'rsatamiz
    final displayStudents = students.length > 15 ? students.sublist(0, 15) : students;
    return Container(
      padding: const EdgeInsets.all(20),
      height: 260,
      decoration: _cardDeco(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(students.length > 15
              ? 'Ball taqsimoti (dastlabki 15 ta)'
              : 'Ball taqsimoti',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${students[groupIndex].name.split(' ')[0]}\n${rod.toY.toStringAsFixed(0)}%',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= displayStudents.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            displayStudents[i].name.split(' ')[0],
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
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
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: displayStudents.asMap().entries.map((e) {
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
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseChart(BuildContext context, bool isDark, List courses) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 240,
      decoration: _cardDeco(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kurslar o\'rtacha bali',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: courses.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.averageScore);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= courses.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
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
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
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

  Widget _buildGroupStats(BuildContext context, bool isDark, List groups) {
    return Column(
      children: groups.take(5).map((group) {
        final scoreColor = group.averageScore >= 75
            ? AppColors.success
            : group.averageScore >= 50
                ? AppColors.warning
                : AppColors.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(isDark),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text('${group.courseName}\n${group.name}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${group.averageScore.toStringAsFixed(1)}%',
                            style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text('${group.studentCount} ta',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: group.averageScore / 100,
                        backgroundColor: scoreColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiskPieChart(BuildContext context, bool isDark, List students) {
    final high =
        students.where((s) => s.scores.level == PerformanceLevel.high).length;
    final medium =
        students.where((s) => s.scores.level == PerformanceLevel.medium).length;
    final low =
        students.where((s) => s.scores.level == PerformanceLevel.low).length;
    final total = students.length;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDeco(isDark),
        child: const Center(child: Text('Ma\'lumot yo\'q')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          Text('O\'quvchilar daraja taqsimoti',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: AppColors.highPerf,
                    value: high.toDouble(),
                    title: '$high\nYuqori',
                    radius: 80,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  PieChartSectionData(
                    color: AppColors.mediumPerf,
                    value: medium.toDouble(),
                    title: '$medium\nO\'rta',
                    radius: 80,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  PieChartSectionData(
                    color: AppColors.lowPerf,
                    value: low.toDouble(),
                    title: '$low\nPast',
                    radius: 80,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _pieLabel(AppColors.highPerf, 'Yuqori',
                  '${(high / total * 100).toStringAsFixed(0)}%'),
              _pieLabel(AppColors.mediumPerf, 'O\'rta',
                  '${(medium / total * 100).toStringAsFixed(0)}%'),
              _pieLabel(AppColors.lowPerf, 'Past',
                  '${(low / total * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pieLabel(Color color, String label, String pct) {
    return Column(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(pct,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  BoxDecoration _cardDeco(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(18),
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
}
