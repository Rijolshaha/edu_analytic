// lib/screens/prediction/prediction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../models/prediction_model.dart';
import '../../services/api_service.dart';

final batchPredictionsProvider =
StateProvider<List<PredictionResult>>((ref) => []);
final batchLoadingProvider = StateProvider<bool>((ref) => false);
final selectedStudentProvider = StateProvider<StudentModel?>((ref) => null);

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

  Future<void> _runBatchPrediction() async {
    ref.read(batchLoadingProvider.notifier).state = true;
    final api = ref.read(apiServiceProvider);
    final results = <PredictionResult>[];

    for (final student in mockStudents) {
      final result = await api.predict(PredictionRequest(
        studentId: student.id,
        attendance: student.scores.attendance,
        homework: student.scores.homework,
        quiz: student.scores.quiz,
        exam: student.scores.exam,
      ));
      results.add(result);
    }

    ref.read(batchPredictionsProvider.notifier).state = results;
    ref.read(batchLoadingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(batchLoadingProvider);
    final predictions = ref.watch(batchPredictionsProvider);

    return Scaffold(

      appBar: AppBar(
        title: const Text('ML Prognoz'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Umumiy prognoz'),
            Tab(text: 'Natijalar'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOverviewTab(context, isDark, isLoading, predictions),
          _buildResultsTab(context, isDark, predictions),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isDark, bool isLoading,
      List<PredictionResult> predictions) {
    final high = predictions.where((p) => p.level == PredictionLevel.high).length;
    final medium = predictions.where((p) => p.level == PredictionLevel.medium).length;
    final low = predictions.where((p) => p.level == PredictionLevel.low).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 48),
                const SizedBox(height: 14),
                const Text('Machine Learning Prognoz',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  '${mockStudents.length} ta o\'quvchi uchun kelajakdagi\no\'zlashtirish darajasini prognoz qiling',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _runBatchPrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5))
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(
                        isLoading
                            ? 'Tahlil qilinmoqda...'
                            : 'Barcha o\'quvchilarni prognoz qilish',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          if (predictions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Prognoz natijalari',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _levelCard('Yuqori', high, AppColors.successGradient,
                        Icons.emoji_events_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _levelCard('O\'rta', medium,
                        AppColors.warningGradient, Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _levelCard(
                        'Past', low, AppColors.dangerGradient, Icons.warning_rounded)),
              ],
            ),
            const SizedBox(height: 20),
            // Risk progress
            _buildRiskBar(context, isDark, high, medium, low,
                predictions.length),
          ],

          if (isLoading) ...[
            const SizedBox(height: 24),
            _buildLoadingIndicator(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _levelCard(
      String label, int count, LinearGradient gradient, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRiskBar(BuildContext context, bool isDark, int high, int medium,
      int low, int total) {
    if (total == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daraja taqsimoti',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  if (high > 0)
                    Flexible(
                      flex: high,
                      child: Container(color: AppColors.highPerf),
                    ),
                  if (medium > 0)
                    Flexible(
                      flex: medium,
                      child: Container(color: AppColors.mediumPerf),
                    ),
                  if (low > 0)
                    Flexible(
                      flex: low,
                      child: Container(color: AppColors.lowPerf),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legend(AppColors.highPerf, 'Yuqori', high, total),
              _legend(AppColors.mediumPerf, 'O\'rta', medium, total),
              _legend(AppColors.lowPerf, 'Past', low, total),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, int count, int total) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count (${(count / total * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, bool isDark) {
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
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('Iltimos kuting',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildResultsTab(BuildContext context, bool isDark,
      List<PredictionResult> predictions) {
    if (predictions.isEmpty) {
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
            Text('"Umumiy prognoz" tabiga boring',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: predictions.length,
      itemBuilder: (ctx, i) =>
          _PredictionCard(prediction: predictions[i], isDark: isDark),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final PredictionResult prediction;
  final bool isDark;
  const _PredictionCard({required this.prediction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isHigh = prediction.level == PredictionLevel.high;
    final isMedium = prediction.level == PredictionLevel.medium;
    final color = isHigh
        ? AppColors.highPerf
        : isMedium
        ? AppColors.mediumPerf
        : AppColors.lowPerf;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Text(prediction.studentName[0],
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prediction.studentName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(prediction.levelLabel,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${prediction.predictedScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              Text('Xavf: ${prediction.riskPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}