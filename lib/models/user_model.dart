// lib/models/user_model.dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        avatar: json['avatar'],
        token: json['token'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'token': token,
      };

  @override
  List<Object?> get props => [id, email];
}
