// lib/screens/students/student_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/student_model.dart';
import '../../models/prediction_model.dart';
import '../../services/api_service.dart';

final predictionStateProvider = StateProvider<PredictionResult?>((ref) => null);
final predictionLoadingProvider = StateProvider<bool>((ref) => false);

class StudentDetailScreen extends ConsumerStatefulWidget {
  final StudentModel student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState
    extends ConsumerState<StudentDetailScreen> {
  late double _attendance;
  late double _homework;
  late double _quiz;
  late double _exam;

  @override
  void initState() {
    super.initState();
    _attendance = widget.student.scores.attendance;
    _homework = widget.student.scores.homework;
    _quiz = widget.student.scores.quiz;
    _exam = widget.student.scores.exam;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(predictionStateProvider.notifier).state = null;
    });
  }

  Future<void> _predict() async {
    ref.read(predictionLoadingProvider.notifier).state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.predict(PredictionRequest(
        studentId: widget.student.id,
        attendance: _attendance,
        homework: _homework,
        quiz: _quiz,
        exam: _exam,
      ));
      ref.read(predictionStateProvider.notifier).state = result;
    } finally {
      ref.read(predictionLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prediction = ref.watch(predictionStateProvider);
    final isLoading = ref.watch(predictionLoadingProvider);
    final student = widget.student;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, student, isDark),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildScoreCards(context, student, isDark),
                const SizedBox(height: 24),
                _buildScoreSliders(context, isDark),
                const SizedBox(height: 24),
                _buildPredictButton(context, isLoading),
                if (prediction != null) ...[
                  const SizedBox(height: 24),
                  _buildPredictionResult(context, prediction, isDark),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, StudentModel student, bool isDark) {
    final level = student.scores.level;
    final color = level == PerformanceLevel.high
        ? AppColors.highPerf
        : level == PerformanceLevel.medium
        ? AppColors.mediumPerf
        : AppColors.lowPerf;

    return SliverAppBar(
      expandedHeight: 220,
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
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(student.name[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    student.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '${student.courseName} · ${student.groupName}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    level == PerformanceLevel.high
                        ? 'Yuqori daraja'
                        : level == PerformanceLevel.medium
                        ? 'O\'rta daraja'
                        : 'Past daraja',
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

  Widget _buildScoreCards(
      BuildContext context, StudentModel student, bool isDark) {
    final cards = [
      _ScoreCard(AppLocalizations.of(context)!.attendance, student.scores.attendance,
          Icons.calendar_today_rounded, AppColors.infoGradient),
      _ScoreCard(AppLocalizations.of(context)!.homework, student.scores.homework,
          Icons.assignment_rounded, AppColors.successGradient),
      _ScoreCard(AppLocalizations.of(context)!.quiz, student.scores.quiz,
          Icons.quiz_rounded, AppColors.warningGradient),
      _ScoreCard(AppLocalizations.of(context)!.exam, student.scores.exam,
          Icons.school_rounded, AppColors.dangerGradient),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.map((c) {
        return Container(
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
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  Text(c.label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreSliders(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prognoz uchun qiymatlarni o\'zgartiring',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Slayderlarni o\'zgartiring va prognoz qiling',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          _buildSlider(context, AppLocalizations.of(context)!.attendance, _attendance, AppColors.info,
                  (v) => setState(() => _attendance = v)),
          _buildSlider(context, AppLocalizations.of(context)!.homework, _homework, AppColors.success,
                  (v) => setState(() => _homework = v)),
          _buildSlider(context, AppLocalizations.of(context)!.quiz, _quiz, AppColors.warning,
                  (v) => setState(() => _quiz = v)),
          _buildSlider(context, AppLocalizations.of(context)!.exam, _exam, AppColors.danger,
                  (v) => setState(() => _exam = v)),
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext context, String label, double value,
      Color color, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${value.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _predict,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : const Icon(Icons.psychology_rounded, color: Colors.white),
        label: Text(
            isLoading ? AppLocalizations.of(context)!.predicting : 'ML Prognoz qilish',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildPredictionResult(
      BuildContext context, PredictionResult prediction, bool isDark) {
    final isHigh = prediction.level == PredictionLevel.high;
    final isMedium = prediction.level == PredictionLevel.medium;
    final color = isHigh
        ? AppColors.highPerf
        : isMedium
        ? AppColors.mediumPerf
        : AppColors.lowPerf;
    final gradient = isHigh
        ? AppColors.successGradient
        : isMedium
        ? AppColors.warningGradient
        : AppColors.dangerGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    isHigh
                        ? Icons.emoji_events_rounded
                        : isMedium
                        ? Icons.trending_up_rounded
                        : Icons.warning_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ML Prognoz natijasi',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    Text(prediction.levelLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _predStat('Prognoz ball',
                    '${prediction.predictedScore.toStringAsFixed(1)}%'),
                const SizedBox(width: 24),
                _predStat('Xavf foizi',
                    '${prediction.riskPercentage.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(prediction.recommendation,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _predStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 13)),
      ],
    );
  }
}

class _ScoreCard {
  final String label;
  final double value;
  final IconData icon;
  final LinearGradient gradient;
  _ScoreCard(this.label, this.value, this.icon, this.gradient);
}