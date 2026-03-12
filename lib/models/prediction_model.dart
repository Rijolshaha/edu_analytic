// lib/models/prediction_model.dart
import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

enum PredictionLevel { high, medium, low }

class PredictionRequest extends Equatable {
  final int studentId;
  final double attendance;
  final double homework;
  final double quiz;
  final double exam;

  const PredictionRequest({
    required this.studentId,
    required this.attendance,
    required this.homework,
    required this.quiz,
    required this.exam,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'attendance': attendance,
        'homework': homework,
        'quiz': quiz,
        'exam': exam,
      };

  @override
  List<Object?> get props => [studentId];
}

class PredictionResult extends Equatable {
  final int studentId;
  final String studentName;
  final PredictionLevel level;
  final double riskPercentage;
  final double predictedScore;
  final String recommendation;
  final DateTime predictedAt;

  const PredictionResult({
    required this.studentId,
    required this.studentName,
    required this.level,
    required this.riskPercentage,
    required this.predictedScore,
    required this.recommendation,
    required this.predictedAt,
  });

  String get levelLabel {
    switch (level) {
      case PredictionLevel.high:
        return AppConstants.highPerformance;
      case PredictionLevel.medium:
        return AppConstants.mediumPerformance;
      case PredictionLevel.low:
        return AppConstants.lowPerformance;
    }
  }

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    PredictionLevel level;
    final levelStr = json['level'] ?? '';
    if (levelStr.contains('High')) {
      level = PredictionLevel.high;
    } else if (levelStr.contains('Medium')) {
      level = PredictionLevel.medium;
    } else {
      level = PredictionLevel.low;
    }

    return PredictionResult(
      studentId: json['student_id'],
      studentName: json['student_name'] ?? '',
      level: level,
      riskPercentage: (json['risk_percentage'] ?? 0).toDouble(),
      predictedScore: (json['predicted_score'] ?? 0).toDouble(),
      recommendation: json['recommendation'] ?? '',
      predictedAt: DateTime.parse(json['predicted_at']),
    );
  }

  // Mock prediction logic
  factory PredictionResult.mock({
    required int studentId,
    required String studentName,
    required double attendance,
    required double homework,
    required double quiz,
    required double exam,
  }) {
    final score = attendance * 0.2 + homework * 0.2 + quiz * 0.3 + exam * 0.3;
    PredictionLevel level;
    double riskPercentage;
    String recommendation;

    if (score >= 70) {
      level = PredictionLevel.high;
      riskPercentage = (100 - score).clamp(0, 30);
      recommendation = "O'quvchi yaxshi natija ko'rsatmoqda. Davom eting!";
    } else if (score >= 40) {
      level = PredictionLevel.medium;
      riskPercentage = (100 - score).clamp(30, 65);
      recommendation = "Qo'shimcha mashg'ulotlar tavsiya etiladi.";
    } else {
      level = PredictionLevel.low;
      riskPercentage = (100 - score).clamp(65, 100);
      recommendation = "Darhol individual yordamga muhtoj!";
    }

    return PredictionResult(
      studentId: studentId,
      studentName: studentName,
      level: level,
      riskPercentage: riskPercentage,
      predictedScore: score,
      recommendation: recommendation,
      predictedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [studentId, predictedAt];
}
