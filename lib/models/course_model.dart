// lib/models/course_model.dart
import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final int id;
  final String name;
  final String description;
  final String subject;
  final int teacherId;
  final int groupCount;
  final int studentCount;
  final double averageScore;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.teacherId,
    this.groupCount = 0,
    this.studentCount = 0,
    this.averageScore = 0.0,
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        subject: json['subject'] ?? '',
        teacherId: json['teacher_id'] as int? ?? 0,
        groupCount: json['group_count'] as int? ?? 0,
        studentCount: json['student_count'] as int? ?? 0,
        averageScore: (json['average_score'] ?? 0.0).toDouble(),
        createdAt: _parseCourseDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'subject': subject,
        'teacher_id': teacherId,
        'group_count': groupCount,
        'student_count': studentCount,
        'average_score': averageScore,
        'created_at': createdAt.toIso8601String(),
      };

  CourseModel copyWith({
    int? id,
    String? name,
    String? description,
    String? subject,
    int? teacherId,
    int? groupCount,
    int? studentCount,
    double? averageScore,
    DateTime? createdAt,
  }) =>
      CourseModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        subject: subject ?? this.subject,
        teacherId: teacherId ?? this.teacherId,
        groupCount: groupCount ?? this.groupCount,
        studentCount: studentCount ?? this.studentCount,
        averageScore: averageScore ?? this.averageScore,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, subject];
}

/// Safe DateTime parser uchun CourseModel'da
DateTime _parseCourseDateTime(dynamic dateStr) {
  if (dateStr == null) return DateTime.now();
  if (dateStr is DateTime) return dateStr;
  if (dateStr is String && dateStr.isEmpty) return DateTime.now();
  try {
    return DateTime.parse(dateStr.toString());
  } catch (_) {
    /*ignore: avoid_print*/
    print('DateTime parsing xatoliki (CourseModel): $dateStr');
    return DateTime.now();
  }
}

// Use coursesProvider from screens/courses/courses_screen.dart to get courses from API
