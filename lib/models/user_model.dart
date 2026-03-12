// lib/models/user_model.dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? username;
  final String? phone;
  final String? subject;
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.username,
    this.phone,
    this.subject,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? 'Unknown',
        email: json['email'] as String? ?? '',
        avatar: json['avatar'] as String?,
        username: json['username'] as String?,
        phone: json['phone'] as String?,
        subject: json['subject'] as String?,
        token: json['token'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'username': username,
        'phone': phone,
        'subject': subject,
        'token': token,
      };

  @override
  List<Object?> get props => [id, email];
}
