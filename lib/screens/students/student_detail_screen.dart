// lib/screens/students/student_detail_screen.dart
// ✅ TUZATILGAN:
//   - _buildSlider va _buildScoreSliders OLIB TASHLANDI
//   - _buildPredictButton API bilan to'g'ri ishlaydi (widget.student.scores ishlatiladi)
//   - Prognoz student'ning REAL joriy ma'lumotlari asosida qilinadi
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/student_model.dart';
import '../../models/prediction_model.dart';
import '../../services/api_service.dart';

// ── Providers ──────────────────────────────────────────────
final predictionStateProvider = StateProvider<PredictionResult?>((ref) => null);
final predictionLoadingProvider = StateProvider<bool>((ref) => false);

final _progressProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, studentId) async {
  final api = ref.read(apiServiceProvider);
  return api.getStudentProgress(studentId, days: 60);
});

// ══════════════════════════════════════════════════════════════
class StudentDetailScreen extends ConsumerStatefulWidget {
  final StudentModel student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(predictionStateProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ✅ FIX: widget.student.scores dan to'g'ridan to'g'ri qiymatlar olinadi
  // Slider kerak emas — real ma'lumotlar API dan keladi
  Future<void> _predict() async {
    ref.read(predictionLoadingProvider.notifier).state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.predict(PredictionRequest(
        studentId: widget.student.id,
        attendance: widget.student.scores.attendance,
        homework:   widget.student.scores.homework,
        quiz:       widget.student.scores.quiz,
        exam:       widget.student.scores.exam,
      ));
      ref.read(predictionStateProvider.notifier).state = result;
      _tabCtrl.animateTo(0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(predictionLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final prediction = ref.watch(predictionStateProvider);
    final isLoading  = ref.watch(predictionLoadingProvider);
    final student    = widget.student;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, student, isDark),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                tabs: const [
                  Tab(text: '📊 Prognoz'),
                  Tab(text: '📈 Progress'),
                ],
              ),
              isDark ? AppColors.darkSurface : Colors.white,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── TAB 1: Prognoz ────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildScoreCards(context, student, isDark),
                      const SizedBox(height: 20),
                      // ✅ _buildScoreSliders o'chirildi — joriy ma'lumotlar karta orqali ko'rinadi
                      _buildInfoBanner(context, student, isDark),
                      const SizedBox(height: 20),
                      // ✅ _buildPredictButton API bilan to'g'ri ishlaydi
                      _buildPredictButton(context, isLoading),
                      if (prediction != null) ...[
                        const SizedBox(height: 24),
                        _buildPredictionResult(context, prediction, isDark),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                // ── TAB 2: Progress grafigi ───────────────
                _ProgressTab(studentId: student.id, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  SliverAppBar _buildAppBar(
      BuildContext context, StudentModel student, bool isDark) {
    final level = student.scores.level;
    final color = level == PerformanceLevel.high
        ? AppColors.highPerf
        : level == PerformanceLevel.medium
            ? AppColors.mediumPerf
            : AppColors.lowPerf;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(student.name[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(student.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 4),
                Text('${student.courseName} · ${student.groupName}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    level == PerformanceLevel.high
                        ? '🏆 Yuqori daraja'
                        : level == PerformanceLevel.medium
                            ? '📈 O\'rta daraja'
                            : '⚠️ Past daraja',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Score kartalar ──────────────────────────────────────────
  Widget _buildScoreCards(
      BuildContext context, StudentModel student, bool isDark) {
    final l = AppLocalizations.of(context)!;
    final cards = [
      _ScoreCardData(l.attendance,  student.scores.attendance, Icons.calendar_today_rounded, AppColors.infoGradient),
      _ScoreCardData(l.homework,    student.scores.homework,   Icons.assignment_rounded,     AppColors.successGradient),
      _ScoreCardData(l.quiz,        student.scores.quiz,       Icons.quiz_rounded,           AppColors.warningGradient),
      _ScoreCardData(l.exam,        student.scores.exam,       Icons.school_rounded,         AppColors.dangerGradient),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.map((c) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: c.gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(c.icon, color: Colors.white, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c.value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text(c.label,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ✅ Slider o'rniga ma'lumot banneri
  Widget _buildInfoBanner(BuildContext context, StudentModel student, bool isDark) {
    final overall = student.scores.overall;
    final color = overall >= 70
        ? AppColors.success
        : overall >= 40
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${overall.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Umumiy ball',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.darkText : AppColors.lightText)),
                const SizedBox(height: 4),
                Text(
                  'Prognoz joriy ma\'lumotlar asosida (davomat, uy vazifasi, quiz, imtihon) hisoblangan ball bo\'yicha amalga oshiriladi.',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: _buildPredictButton — API ni to'g'ri chaqiradi, slider yo'q
  Widget _buildPredictButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _predict,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: isLoading ? 0 : 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
        label: Text(
          isLoading ? 'Prognoz hisoblanmoqda...' : 'ML Prognoz qilish',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Prognoz natijasi ────────────────────────────────────────
  Widget _buildPredictionResult(
      BuildContext context, PredictionResult prediction, bool isDark) {
    final isHigh   = prediction.level == PredictionLevel.high;
    final isMedium = prediction.level == PredictionLevel.medium;
    final color    = isHigh ? AppColors.highPerf : isMedium ? AppColors.mediumPerf : AppColors.lowPerf;
    final gradient = isHigh ? AppColors.successGradient : isMedium ? AppColors.warningGradient : AppColors.dangerGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHigh ? Icons.emoji_events_rounded : isMedium ? Icons.trending_up_rounded : Icons.warning_rounded,
                    color: Colors.white, size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ML Prognoz natijasi',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text(prediction.levelLabel,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _predStat('Prognoz ball', '${prediction.predictedScore.toStringAsFixed(1)}%'),
                const SizedBox(width: 24),
                _predStat('Xavf foizi', '${prediction.riskPercentage.toStringAsFixed(0)}%'),
              ],
            ),
            if (prediction.recommendation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prediction.recommendation.split('\n').first,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
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

  Widget _predStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PROGRESS TAB
// ══════════════════════════════════════════════════════════════
class _ProgressTab extends ConsumerWidget {
  final int studentId;
  final bool isDark;
  const _ProgressTab({required this.studentId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(_progressProvider(studentId));

    return progressAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Progress yuklanmoqda...'),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            const Text('Progress ma\'lumotlari yuklanmadi'),
            const SizedBox(height: 8),
            Text(e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(_progressProvider(studentId)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Qayta urinib ko\'ring'),
            ),
          ],
        ),
      ),
      data: (progress) => _buildProgressContent(context, progress),
    );
  }

  Widget _buildProgressContent(BuildContext context, Map<String, dynamic> progress) {
    final currentScore = progress['current_score'] as Map? ?? {};
    final attHistory   = progress['attendance_history'] as List? ?? [];
    final hwHistory    = progress['homework_history']   as List? ?? [];
    final quizHistory  = progress['quiz_history']       as List? ?? [];
    final trends       = progress['trends']  as Map? ?? {};
    final summary      = progress['summary'] as Map? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentScores(context, currentScore),
          const SizedBox(height: 20),
          _buildTrends(context, trends, summary),
          const SizedBox(height: 20),
          if (attHistory.isNotEmpty) ...[
            _sectionTitle(context, '📅 Davomat tarixi'),
            const SizedBox(height: 12),
            _buildAttendanceChart(context, attHistory),
            const SizedBox(height: 20),
          ],
          if (hwHistory.isNotEmpty) ...[
            _sectionTitle(context, '📝 Uy vazifasi natijalari'),
            const SizedBox(height: 12),
            _buildHomeworkChart(context, hwHistory),
            const SizedBox(height: 20),
          ],
          if (quizHistory.isNotEmpty) ...[
            _sectionTitle(context, '📊 Quiz natijalari'),
            const SizedBox(height: 12),
            _buildQuizChart(context, quizHistory),
            const SizedBox(height: 20),
          ],
          if (attHistory.isEmpty && hwHistory.isEmpty && quizHistory.isEmpty)
            _buildNoData(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCurrentScores(BuildContext context, Map currentScore) {
    final att      = (currentScore['attendance'] ?? 0).toDouble();
    final hw       = (currentScore['homework'] ?? 0).toDouble();
    final quiz     = (currentScore['quiz'] ?? 0).toDouble();
    final exam     = (currentScore['exam'] ?? 0).toDouble();
    final weighted = (currentScore['weighted'] ?? 0).toDouble();

    final items = [
      _ScoreItem('Davomat', att, AppColors.info),
      _ScoreItem('Uy vazifasi', hw, AppColors.success),
      _ScoreItem('Quiz', quiz, AppColors.warning),
      _ScoreItem('Imtihon', exam, AppColors.danger),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Joriy ko\'rsatkichlar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${weighted.toStringAsFixed(1)}% umumiy',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) => Expanded(
              child: Column(
                children: [
                  Text('${item.value.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(item.label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (item.value / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrends(BuildContext context, Map trends, Map summary) {
    final isImproving       = summary['improving']          as bool? ?? false;
    final isAtRisk          = summary['at_risk']            as bool? ?? false;
    final consecutiveAbsent = trends['consecutive_absent']  as int?  ?? 0;

    return Row(
      children: [
        Expanded(child: _trendCard(
          icon: isImproving ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
          label: isImproving ? 'Yaxshilanmoqda' : 'Barqaror',
          color: isImproving ? AppColors.success : AppColors.warning,
        )),
        const SizedBox(width: 10),
        Expanded(child: _trendCard(
          icon: isAtRisk ? Icons.warning_rounded : Icons.check_circle_rounded,
          label: isAtRisk ? 'Xavf ostida' : 'Xavf yo\'q',
          color: isAtRisk ? AppColors.danger : AppColors.success,
        )),
        const SizedBox(width: 10),
        Expanded(child: _trendCard(
          icon: Icons.event_busy_rounded,
          label: '$consecutiveAbsent\nketma-ket',
          color: consecutiveAbsent > 0 ? AppColors.danger : AppColors.info,
        )),
      ],
    );
  }

  Widget _trendCard({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart(BuildContext context, List history) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Haftalik davomat foizi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(LineChartData(
              minY: 0, maxY: 100,
              lineBarsData: [LineChartBarData(
                spots: history.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), (e.value['rate'] ?? 0).toDouble())).toList(),
                isCurved: true, color: AppColors.info, barWidth: 3,
                dotData: FlDotData(getDotPainter: (s, p, b, i) =>
                    FlDotCirclePainter(radius: 4, color: AppColors.info, strokeWidth: 2, strokeColor: Colors.white)),
                belowBarData: BarAreaData(show: true, color: AppColors.info.withOpacity(0.1)),
              )],
              titlesData: _chartTitles(history, 'week', isDark),
              borderData: FlBorderData(show: false),
              gridData: _gridData(isDark),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkChart(BuildContext context, List history) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uy vazifasi foizi (oxirgi ${history.length} ta)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(BarChartData(
              maxY: 100,
              barGroups: history.asMap().entries.map((e) {
                final pct = (e.value['percentage'] ?? 0).toDouble();
                final color = pct >= 70 ? AppColors.success : pct >= 40 ? AppColors.warning : AppColors.danger;
                return BarChartGroupData(x: e.key, barRods: [BarChartRodData(
                  toY: pct, color: color, width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )]);
              }).toList(),
              titlesData: _chartTitles(history, 'date', isDark),
              borderData: FlBorderData(show: false),
              gridData: _gridData(isDark),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizChart(BuildContext context, List history) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quiz/Sinf ishi natijalari',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(LineChartData(
              minY: 0, maxY: 100,
              lineBarsData: [LineChartBarData(
                spots: history.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), (e.value['percentage'] ?? 0).toDouble())).toList(),
                isCurved: true, color: AppColors.warning, barWidth: 3,
                dotData: FlDotData(getDotPainter: (s, p, b, i) =>
                    FlDotCirclePainter(radius: 4, color: AppColors.warning, strokeWidth: 2, strokeColor: Colors.white)),
                belowBarData: BarAreaData(show: true, color: AppColors.warning.withOpacity(0.1)),
              )],
              titlesData: _chartTitles(history, 'date', isDark),
              borderData: FlBorderData(show: false),
              gridData: _gridData(isDark),
            )),
          ),
        ],
      ),
    );
  }

  FlTitlesData _chartTitles(List history, String dateKey, bool isDark) {
    return FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= history.length) return const SizedBox();
          final date = history[i][dateKey]?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(date.length >= 5 ? date.substring(5) : date,
                style: TextStyle(fontSize: 8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          );
        },
      )),
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, interval: 25,
        getTitlesWidget: (v, m) => Text('${v.toInt()}',
            style: const TextStyle(fontSize: 9)),
      )),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _gridData(bool isDark) => FlGridData(
    show: true, drawVerticalLine: false, horizontalInterval: 25,
    getDrawingHorizontalLine: (_) => FlLine(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder, strokeWidth: 1,
    ),
  );

  Widget _buildNoData(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Progress ma\'lumotlari yo\'q',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Davomat, uy vazifasi va quiz\nma\'lumotlarini kiritgandan so\'ng\ngrafik ko\'rinadi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: isDark ? AppColors.darkCard : Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
  );
}

// ── Helper Models ───────────────────────────────────────────
class _ScoreCardData {
  final String label;
  final double value;
  final IconData icon;
  final LinearGradient gradient;
  _ScoreCardData(this.label, this.value, this.icon, this.gradient);
}

class _ScoreItem {
  final String label;
  final double value;
  final Color color;
  _ScoreItem(this.label, this.value, this.color);
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override double get maxExtent => tabBar.preferredSize.height;
  @override double get minExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
