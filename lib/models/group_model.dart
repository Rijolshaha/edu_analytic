// lib/models/group_model.dart
import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  final int id;
  final String name;
  final int courseId;
  final String courseName;
  final int studentCount;
  final double averageScore;
  final int atRiskCount;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.courseName,
    this.studentCount = 0,
    this.averageScore = 0.0,
    this.atRiskCount = 0,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] ?? '',
        courseId: (json['course_id'] ?? json['course']) as int? ?? 0,
        courseName: json['course_name'] ?? '',
        studentCount: json['student_count'] as int? ?? 0,
        averageScore: (json['average_score'] ?? 0.0).toDouble(),
        atRiskCount: json['at_risk_count'] as int? ?? 0,
        createdAt: _parseGroupDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'course_id': courseId,
        'course_name': courseName,
        'student_count': studentCount,
        'average_score': averageScore,
        'at_risk_count': atRiskCount,
        'created_at': createdAt.toIso8601String(),
      };

  GroupModel copyWith({
    String? name,
    int? studentCount,
    double? averageScore,
    int? atRiskCount,
  }) =>
      GroupModel(
        id: id,
        name: name ?? this.name,
        courseId: courseId,
        courseName: courseName,
        studentCount: studentCount ?? this.studentCount,
        averageScore: averageScore ?? this.averageScore,
        atRiskCount: atRiskCount ?? this.atRiskCount,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, courseId];
}

/// Safe DateTime parser uchun GroupModel'da
DateTime _parseGroupDateTime(dynamic dateStr) {
  if (dateStr == null) return DateTime.now();
  if (dateStr is DateTime) return dateStr;
  if (dateStr is String && dateStr.isEmpty) return DateTime.now();
  try {
    return DateTime.parse(dateStr.toString());
  } catch (_) {
    /*ignore: avoid_print*/
    print('DateTime parsing xatoliki (GroupModel): $dateStr');
    return DateTime.now();
  }
}

final List<GroupModel> mockGroups = [
  GroupModel(
      id: 1,
      name: 'A-guruh',
      courseId: 1,
      courseName: 'Matematika',
      studentCount: 25,
      averageScore: 76.3,
      atRiskCount: 3,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 2,
      name: 'B-guruh',
      courseId: 1,
      courseName: 'Matematika',
      studentCount: 24,
      averageScore: 71.8,
      atRiskCount: 5,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 3,
      name: 'C-guruh',
      courseId: 1,
      courseName: 'Matematika',
      studentCount: 23,
      averageScore: 75.4,
      atRiskCount: 2,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 4,
      name: 'A-guruh',
      courseId: 2,
      courseName: 'Fizika',
      studentCount: 25,
      averageScore: 69.5,
      atRiskCount: 6,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 5,
      name: 'B-guruh',
      courseId: 2,
      courseName: 'Fizika',
      studentCount: 23,
      averageScore: 67.0,
      atRiskCount: 7,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 6,
      name: 'A-guruh',
      courseId: 3,
      courseName: 'Informatika',
      studentCount: 26,
      averageScore: 83.2,
      atRiskCount: 1,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 7,
      name: 'B-guruh',
      courseId: 3,
      courseName: 'Informatika',
      studentCount: 24,
      averageScore: 80.1,
      atRiskCount: 2,
      createdAt: DateTime(2024, 9, 1)),
  GroupModel(
      id: 8,
      name: 'C-guruh',
      courseId: 3,
      courseName: 'Informatika',
      studentCount: 25,
      averageScore: 81.7,
      atRiskCount: 2,
      createdAt: DateTime(2024, 9, 1)),
];
