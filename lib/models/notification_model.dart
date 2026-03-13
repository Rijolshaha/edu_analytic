// lib/models/notification_model.dart
import 'package:equatable/equatable.dart';

enum NotificationType { atRisk, attendance, grade, general }

class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final int? studentId;
  final int? courseId;
  final int? groupId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.studentId,
    this.courseId,
    this.groupId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    final typeStr = json['type'] ?? json['notification_type'] ?? 'general';
    if (typeStr.toString().toLowerCase().contains('risk')) {
      type = NotificationType.atRisk;
    } else if (typeStr.toString().toLowerCase().contains('attendance')) {
      type = NotificationType.attendance;
    } else if (typeStr.toString().toLowerCase().contains('grade')) {
      type = NotificationType.grade;
    } else {
      type = NotificationType.general;
    }

    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      type: type,
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
              DateTime.now(),
      studentId: json['student_id'],
      courseId: json['course_id'],
      groupId: json['group_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        'student_id': studentId,
        'course_id': courseId,
        'group_id': groupId,
      };

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    int? studentId,
    int? courseId,
    int? groupId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, isRead, createdAt];
}
