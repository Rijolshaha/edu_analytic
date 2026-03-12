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
        id: json['id'],
        name: json['name'],
        email: json['email'],
        avatar: json['avatar'],
        username: json['username'],
        phone: json['phone'],
        subject: json['subject'],
        token: json['token'],
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
