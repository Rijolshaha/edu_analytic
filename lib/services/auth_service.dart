// lib/services/auth_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Saqlangan foydalanuvchini storage dan yuklaydi
final storedUserProvider = FutureProvider<UserModel?>((ref) async {
  final auth = ref.read(authServiceProvider);
  return auth.getUser();
});

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref.read(authServiceProvider));
});

class AuthService {
  // ── Token ──────────────────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${AppConstants.tokenKey}_refresh');
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.tokenKey}_refresh', token);
  }

  // ── User ───────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  // ── Logout ─────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove('${AppConstants.tokenKey}_refresh');
    await prefs.remove(AppConstants.userKey);
  }

  // ── Auth check ─────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Token Refresh ──────────────────────────────────────
  Future<bool> refreshToken(Dio dio) async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await dio.post(
        'auth/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final newToken =
          response.data['access'] ?? response.data['token'] as String?;
      if (newToken != null) {
        await saveToken(newToken);
        return true;
      }
      return false;
    } catch (_) {
      await logout();
      return false;
    }
  }
}

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(null) {
    // App ishga tushganda storage dan foydalanuvchini yuklaymiz
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final user = await _authService.getUser();
    if (user != null && mounted) {
      state = user;
    }
  }

  void setUser(UserModel user) => state = user;
  void clearUser() => state = null;
}
