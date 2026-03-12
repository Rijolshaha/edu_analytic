// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../models/prediction_model.dart';
import 'auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class ApiService {
  late final Dio _dio;
  final AuthService _authService;
  static const String tag = '🌐 [API]';

  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _authService.refreshToken(_dio);
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await _authService.getToken();
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        // 500 errors - log backend error
        if (error.response?.statusCode == 500) {
          /*ignore: avoid_print*/
          print('$tag Backend 500 Error:');
          /*ignore: avoid_print*/
          print('$tag URL: ${error.requestOptions.path}');
          /*ignore: avoid_print*/
          print('$tag Response: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  /// Backend response parsing helper
  /// Supported formats:
  /// 1. Direct list: [...]
  /// 2. DRF pagination: {results: [...], count: ...}
  /// 3. Wrapped: {data: [...]}
  List _parseListResponse(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data.containsKey('results')) return data['results'] as List? ?? [];
      if (data.containsKey('data')) return data['data'] as List? ?? [];
    }
    return [];
  }

  // AUTH — trailing slash YOQ (Django URL pattern shunday)
  Future<UserModel> login(String username, String password) async {
    try {
      /*ignore: avoid_print*/
      print('$tag Logging in: $username');
      final response = await _dio.post(
        'auth/login',
        data: {'username': username, 'password': password},
      );
      final data = response.data;
      final token = (data['token'] ?? data['access'] ?? '') as String;
      await _authService.saveToken(token);
      final refresh = data['refresh'] as String?;
      if (refresh != null) await _authService.saveRefreshToken(refresh);
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      final user = UserModel.fromJson({...userMap, 'token': token});
      await _authService.saveUser(user);
      /*ignore: avoid_print*/
      print('$tag Login successful: ${user.name}');
      return user;
    } on DioException catch (e) {
      /*ignore: avoid_print*/
      print('$tag Login error [${e.response?.statusCode}]: ${e.message}');
      /*ignore: avoid_print*/
      print('$tag Response: ${e.response?.data}');

      // User-friendly error message
      final errorMsg = _getErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      /*ignore: avoid_print*/
      print('$tag Login error: $e');
      rethrow;
    }
  }

  /// Extract user-friendly error message from DioException
  String _getErrorMessage(DioException e) {
    if (e.response?.statusCode == 500) {
      return 'Server xatosi. Iltimos, keyinroq qayta urinib ko\'ring.';
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map) {
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('message')) return data['message'].toString();
      }
      return 'Login yoki parol noto\'g\'ri';
    }
    if (e.response?.statusCode == 404) {
      return 'Server topilmadi. URL ni tekshiring.';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Ulanish vaqti tugadi. Internetni tekshiring.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server javob bermadi. Iltimos, qayta urinib ko\'ring.';
    }
    return e.message ?? 'Noma\'lum xatolik';
  }

  // AUTH — Registration
  Future<UserModel> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String password2,
    String? phone,
    String? subject,
  }) async {
    try {
      /*ignore: avoid_print*/
      print('$tag Registering: $email');
      final response = await _dio.post(
        'auth/register',
        data: {
          'username': username,
          'name': name,
          'email': email,
          'password': password,
          'password2': password2,
          'phone': phone ?? '',
          'subject': subject ?? '',
        },
      );
      final data = response.data;
      final token = (data['token'] ?? data['access'] ?? '') as String;
      await _authService.saveToken(token);
      final refresh = data['refresh'] as String?;
      if (refresh != null) await _authService.saveRefreshToken(refresh);
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      final user = UserModel.fromJson({...userMap, 'token': token});
      await _authService.saveUser(user);
      /*ignore: avoid_print*/
      print('$tag Registration successful: ${user.name}');
      return user;
    } on DioException catch (e) {
      /*ignore: avoid_print*/
      print('$tag Register error [${e.response?.statusCode}]: ${e.message}');
      /*ignore: avoid_print*/
      print('$tag Response: ${e.response?.data}');

      // User-friendly error message
      final errorMsg = _getErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      /*ignore: avoid_print*/
      print('$tag Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('auth/logout');
    } catch (_) {}
    await _authService.logout();
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get('auth/me');
    final token = await _authService.getToken();
    return UserModel.fromJson({...response.data, 'token': token ?? ''});
  }

  // COURSES
  Future<List<CourseModel>> getCourses() async {
    final response = await _dio.get('courses/');
    // Django REST Framework pagination bo'lsa: {results: [...], count: ...}
    // Va bo'lmasa: [...]  yoki {data: [...]}
    final List list = _parseListResponse(response.data);
    return list.map((e) => CourseModel.fromJson(e)).toList();
  }

  Future<CourseModel> getCourse(int id) async {
    final response = await _dio.get('courses/$id/');
    return CourseModel.fromJson(response.data);
  }

  Future<CourseModel> createCourse(Map<String, dynamic> data) async {
    final response = await _dio.post('courses/', data: data);
    return CourseModel.fromJson(response.data);
  }

  Future<CourseModel> updateCourse(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('courses/$id/', data: data);
    return CourseModel.fromJson(response.data);
  }

  Future<void> deleteCourse(int id) async {
    await _dio.delete('courses/$id/');
  }

  // GROUPS
  Future<List<GroupModel>> getGroups({int? courseId}) async {
    final response = await _dio.get('groups/',
        queryParameters: courseId != null ? {'course_id': courseId} : null);
    final List list = _parseListResponse(response.data);
    return list.map((e) => GroupModel.fromJson(e)).toList();
  }

  Future<GroupModel> getGroup(int id) async {
    final response = await _dio.get('groups/$id/');
    return GroupModel.fromJson(response.data);
  }

  Future<GroupModel> createGroup(Map<String, dynamic> data) async {
    final response = await _dio.post('groups/', data: data);
    return GroupModel.fromJson(response.data);
  }

  Future<GroupModel> updateGroup(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('groups/$id/', data: data);
    return GroupModel.fromJson(response.data);
  }

  Future<void> deleteGroup(int id) async {
    await _dio.delete('groups/$id/');
  }

  // STUDENTS
  Future<List<StudentModel>> getStudents({int? groupId, int? courseId}) async {
    final Map<String, dynamic> params = {};
    if (groupId != null) params['group_id'] = groupId;
    if (courseId != null) params['course_id'] = courseId;
    final response = await _dio.get('students/',
        queryParameters: params.isNotEmpty ? params : null);
    final List list = _parseListResponse(response.data);
    return list.map((e) => StudentModel.fromJson(e)).toList();
  }

  Future<StudentModel> getStudent(int id) async {
    final response = await _dio.get('students/$id/');
    return StudentModel.fromJson(response.data);
  }

  Future<StudentModel> createStudent(Map<String, dynamic> data) async {
    final response = await _dio.post('students/', data: data);
    return StudentModel.fromJson(response.data);
  }

  Future<StudentModel> updateStudent(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('students/$id/', data: data);
    return StudentModel.fromJson(response.data);
  }

  Future<void> deleteStudent(int id) async {
    await _dio.delete('students/$id/');
  }

  // PREDICTION
  Future<PredictionResult> predict(PredictionRequest request) async {
    final response = await _dio.post('predict/', data: request.toJson());
    return PredictionResult.fromJson(response.data);
  }

  // STATS
  Future<Map<String, dynamic>> getOverviewStats() async {
    final response = await _dio.get('stats/overview/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<StudentModel>> getAtRiskStudents() async {
    final response = await _dio.get('stats/at-risk/');
    final List list = _parseListResponse(response.data);
    return list.map((e) => StudentModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getCourseStats(int courseId) async {
    final response = await _dio.get('stats/courses/$courseId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupStats(int groupId) async {
    final response = await _dio.get('stats/groups/$groupId/');
    return response.data as Map<String, dynamic>;
  }
}
