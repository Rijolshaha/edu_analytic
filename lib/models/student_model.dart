// lib/models/student_model.dart
import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

enum PerformanceLevel { high, medium, low }

class StudentScores extends Equatable {
  final double attendance; // 0-100 %
  final double homework; // 0-100
  final double quiz; // 0-100
  final double exam; // 0-100

  const StudentScores({
    this.attendance = 0,
    this.homework = 0,
    this.quiz = 0,
    this.exam = 0,
  });

  double get overall =>
      (attendance * 0.2 + homework * 0.2 + quiz * 0.3 + exam * 0.3);

  PerformanceLevel get level {
    final score = overall;
    if (score >= AppConstants.highScoreMin) return PerformanceLevel.high;
    if (score >= AppConstants.mediumScoreMin) return PerformanceLevel.medium;
    return PerformanceLevel.low;
  }

  factory StudentScores.fromJson(Map<String, dynamic> json) => StudentScores(
        attendance: (json['attendance'] ?? 0).toDouble(),
        homework: (json['homework'] ?? 0).toDouble(),
        quiz: (json['quiz'] ?? 0).toDouble(),
        exam: (json['exam'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'attendance': attendance,
        'homework': homework,
        'quiz': quiz,
        'exam': exam,
      };

  @override
  List<Object?> get props => [attendance, homework, quiz, exam];
}

class StudentModel extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? avatar;
  final int groupId;
  final String groupName;
  final int courseId;
  final String courseName;
  final StudentScores scores;
  final DateTime enrolledAt;

  const StudentModel({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    required this.groupId,
    required this.groupName,
    required this.courseId,
    required this.courseName,
    this.scores = const StudentScores(),
    required this.enrolledAt,
  });

  bool get isAtRisk => scores.level == PerformanceLevel.low;

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] ?? '',
        email: json['email'],
        avatar: json['avatar'],
        groupId: (json['group_id'] ?? json['group']) as int? ?? 0,
        groupName: json['group_name'] ?? '',
        courseId: json['course_id'] as int? ?? 0,
        courseName: json['course_name'] ?? '',
        scores: StudentScores.fromJson(json['scores'] ?? {}),
        enrolledAt: _parseDateTime(json['enrolled_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'group_id': groupId,
        'group_name': groupName,
        'course_id': courseId,
        'course_name': courseName,
        'scores': scores.toJson(),
        'enrolled_at': enrolledAt.toIso8601String(),
      };

  StudentModel copyWith({
    String? name,
    String? email,
    StudentScores? scores,
  }) =>
      StudentModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatar: avatar,
        groupId: groupId,
        groupName: groupName,
        courseId: courseId,
        courseName: courseName,
        scores: scores ?? this.scores,
        enrolledAt: enrolledAt,
      );

  @override
  List<Object?> get props => [id, name, groupId];
}

/// Safe DateTime parser (Backend xatolikka bardavom berish uchun)
DateTime _parseDateTime(dynamic dateStr) {
  if (dateStr == null) return DateTime.now();
  if (dateStr is DateTime) return dateStr;
  if (dateStr is String && dateStr.isEmpty) return DateTime.now();
  try {
    return DateTime.parse(dateStr.toString());
  } catch (_) {
    /*ignore: avoid_print*/
    print('DateTime parsing xatoliki: $dateStr');
    return DateTime.now();
  }
}

final List<StudentModel> mockStudents = [
  StudentModel(
      id: 1,
      name: 'Alibek Karimov',
      email: 'alibek@mail.uz',
      groupId: 1,
      groupName: 'A-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 92, homework: 85, quiz: 78, exam: 80),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 2,
      name: 'Zulfiya Rahimova',
      email: 'zulfiya@mail.uz',
      groupId: 1,
      groupName: 'A-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 88, homework: 90, quiz: 92, exam: 88),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 3,
      name: 'Jasur Toshmatov',
      email: 'jasur@mail.uz',
      groupId: 1,
      groupName: 'A-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 45, homework: 38, quiz: 42, exam: 35),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 4,
      name: 'Nilufar Hasanova',
      email: 'nilufar@mail.uz',
      groupId: 1,
      groupName: 'A-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 75, homework: 70, quiz: 65, exam: 72),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 5,
      name: 'Bobur Yusupov',
      email: 'bobur@mail.uz',
      groupId: 2,
      groupName: 'B-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 55, homework: 48, quiz: 52, exam: 45),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 6,
      name: 'Dilnoza Mirzayeva',
      email: 'dilnoza@mail.uz',
      groupId: 2,
      groupName: 'B-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 95, homework: 88, quiz: 94, exam: 91),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 7,
      name: 'Sardor Nazarov',
      email: 'sardor@mail.uz',
      groupId: 3,
      groupName: 'C-guruh',
      courseId: 1,
      courseName: 'Matematika',
      scores:
          const StudentScores(attendance: 82, homework: 76, quiz: 80, exam: 78),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 8,
      name: 'Kamola Ergasheva',
      email: 'kamola@mail.uz',
      groupId: 4,
      groupName: 'A-guruh',
      courseId: 2,
      courseName: 'Fizika',
      scores:
          const StudentScores(attendance: 38, homework: 42, quiz: 35, exam: 40),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 9,
      name: 'Sherzod Tursunov',
      email: 'sherzod@mail.uz',
      groupId: 4,
      groupName: 'A-guruh',
      courseId: 2,
      courseName: 'Fizika',
      scores:
          const StudentScores(attendance: 78, homework: 72, quiz: 68, exam: 74),
      enrolledAt: DateTime(2024, 9, 1)),
  StudentModel(
      id: 10,
      name: 'Mohira Xoliqova',
      email: 'mohira@mail.uz',
      groupId: 6,
      groupName: 'A-guruh',
      courseId: 3,
      courseName: 'Informatika',
      scores:
          const StudentScores(attendance: 98, homework: 95, quiz: 96, exam: 94),
      enrolledAt: DateTime(2024, 9, 1)),
];
