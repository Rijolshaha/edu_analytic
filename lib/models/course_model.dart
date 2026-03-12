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
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        subject: json['subject'] ?? '',
        teacherId: json['teacher_id'],
        groupCount: json['group_count'] ?? 0,
        studentCount: json['student_count'] ?? 0,
        averageScore: (json['average_score'] ?? 0.0).toDouble(),
        createdAt: DateTime.parse(json['created_at']),
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

// Mock data
final List<CourseModel> mockCourses = [
  CourseModel(id: 1, name: 'Matematika', description: 'Algebra va geometriya', subject: 'math', teacherId: 1, groupCount: 3, studentCount: 72, averageScore: 74.5, createdAt: DateTime(2024, 9, 1)),
  CourseModel(id: 2, name: 'Fizika', description: 'Mexanika va optika', subject: 'physics', teacherId: 1, groupCount: 2, studentCount: 48, averageScore: 68.2, createdAt: DateTime(2024, 9, 1)),
  CourseModel(id: 3, name: 'Informatika', description: 'Dasturlash asoslari', subject: 'cs', teacherId: 1, groupCount: 4, studentCount: 96, averageScore: 81.3, createdAt: DateTime(2024, 9, 1)),
  CourseModel(id: 4, name: 'Ingliz tili', description: 'B1-B2 darajasi', subject: 'english', teacherId: 1, groupCount: 2, studentCount: 44, averageScore: 72.8, createdAt: DateTime(2024, 9, 1)),
];
