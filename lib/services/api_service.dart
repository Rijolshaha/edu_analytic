// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../models/prediction_model.dart';
import '../models/notification_model.dart';
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
        if (error.response?.statusCode == 500) {
          print('$tag 500 Error: ${error.requestOptions.path}');
          print('$tag Response: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  // ── Response parser ───────────────────────────────────────
  List _parseListResponse(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data.containsKey('results')) return data['results'] as List? ?? [];
      if (data.containsKey('data')) return data['data'] as List? ?? [];
    }
    return [];
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.statusCode == 500) {
      return 'Server xatosi. Iltimos, keyinroq qayta urinib ko\'ring.';
    }
    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map) {
        // error.message yoki error.code
        if (data['error'] is Map) {
          final err = data['error'] as Map;
          if (err['message'] is Map) {
            final msgs = <String>[];
            (err['message'] as Map).forEach((k, v) {
              if (v is List) msgs.add('$k: ${v.join(", ")}');
              else msgs.add('$k: $v');
            });
            return msgs.join('\n');
          }
          return err['message']?.toString() ?? 'Validatsiya xatosi';
        }
        final errors = StringBuffer();
        data.forEach((k, v) {
          if (v is List && v.isNotEmpty) errors.write('$k: ${v.join(", ")}. ');
          else if (v is String) errors.write('$k: $v. ');
        });
        if (errors.isNotEmpty) return errors.toString();
      }
      return 'Ma\'lumotlarni qayta tekshiring.';
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map) {
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('message')) return data['message'].toString();
        if (data['error'] is Map) return (data['error'] as Map)['message']?.toString() ?? 'Xato';
      }
      return 'Login yoki parol noto\'g\'ri';
    }
    if (e.response?.statusCode == 404) return 'Ma\'lumot topilmadi.';
    if (e.type == DioExceptionType.connectionTimeout) return 'Ulanish vaqti tugadi.';
    if (e.type == DioExceptionType.receiveTimeout) return 'Server javob bermadi.';
    return e.message ?? 'Noma\'lum xatolik';
  }

  // ══════════════════════════════════════════════════════════
  //  AUTH
  // ══════════════════════════════════════════════════════════
  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _dio.post('auth/login/',
          data: {'username': username, 'password': password});
      final data = response.data;
      final token = (data['token'] ?? data['access'] ?? '') as String;
      await _authService.saveToken(token);
      final refresh = data['refresh'] as String?;
      if (refresh != null) await _authService.saveRefreshToken(refresh);
      Map<String, dynamic> userMap;
      if (data.containsKey('user') && data['user'] is Map) {
        userMap = data['user'] as Map<String, dynamic>;
      } else {
        userMap = data;
      }
      final user = UserModel.fromJson({...userMap, 'token': token});
      await _authService.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

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
      final response = await _dio.post('auth/register/', data: {
        'username': username, 'name': name, 'email': email,
        'password': password, 'password2': password2,
        'phone': phone ?? '', 'subject': subject ?? '',
      });
      final data = response.data;
      final token = (data['token'] ?? data['access'] ?? '') as String;
      await _authService.saveToken(token);
      final refresh = data['refresh'] as String?;
      if (refresh != null) await _authService.saveRefreshToken(refresh);
      Map<String, dynamic> userMap;
      if (data.containsKey('user') && data['user'] is Map) {
        userMap = data['user'] as Map<String, dynamic>;
      } else {
        userMap = data;
      }
      final user = UserModel.fromJson({...userMap, 'token': token});
      await _authService.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _authService.getRefreshToken();
      if (refresh != null) {
        await _dio.post('auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {}
    await _authService.logout();
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get('auth/me/');
    final token = await _authService.getToken();
    return UserModel.fromJson({...response.data, 'token': token ?? ''});
  }

  // ══════════════════════════════════════════════════════════
  //  COURSES — faqat o'qituvchiga tegishli
  // ══════════════════════════════════════════════════════════
  Future<List<CourseModel>> getCourses() async {
    final response = await _dio.get('courses/');
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
    final response = await _dio.patch('courses/$id/', data: data);
    return CourseModel.fromJson(response.data);
  }

  Future<void> deleteCourse(int id) async {
    await _dio.delete('courses/$id/');
  }

  // ══════════════════════════════════════════════════════════
  //  GROUPS — faqat o'qituvchiga tegishli guruhlar
  // ══════════════════════════════════════════════════════════
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

  // ══════════════════════════════════════════════════════════
  //  STUDENTS — faqat o'qituvchiga tegishli o'quvchilar
  //  Backend: StudentListCreateView → group__course__teacher=user
  // ══════════════════════════════════════════════════════════
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

  // ── Student progress & history ────────────────────────────
  Future<Map<String, dynamic>> getStudentProgress(int studentId,
      {int days = 60}) async {
    try {
      final response = await _dio.get('students/$studentId/progress/',
          queryParameters: {'days': days});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getStudentAttendance(int studentId,
      {int days = 30}) async {
    final response = await _dio
        .get('students/$studentId/attendance/', queryParameters: {'days': days});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStudentHomework(int studentId,
      {int days = 30}) async {
    final response = await _dio.get('students/$studentId/homework/',
        queryParameters: {'days': days});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStudentQuiz(int studentId,
      {int days = 90}) async {
    final response = await _dio.get('students/$studentId/quiz/',
        queryParameters: {'days': days});
    return response.data as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════════════════
  //  BULK KIRITISH ENDPOINTLARI
  // ══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> bulkAttendance(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('attendance/bulk/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('$tag Bulk attendance error: ${e.response?.data}');
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> bulkHomework(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('homework/bulk/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('$tag Bulk homework error: ${e.response?.data}');
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> bulkQuiz(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('quiz/bulk/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('$tag Bulk quiz error: ${e.response?.data}');
      throw Exception(_getErrorMessage(e));
    }
  }

  // ══════════════════════════════════════════════════════════
  //  PREDICTION
  //  Backend: faqat teacher ga tegishli o'quvchilarni qabul qiladi
  // ══════════════════════════════════════════════════════════

  /// Bitta o'quvchi uchun prognoz — POST /api/v1/predict/
  Future<PredictionResult> predict(PredictionRequest request) async {
    try {
      final response = await _dio.post('predict/', data: {
        'student_id': request.studentId,
        'attendance': request.attendance.toDouble(),
        'homework': request.homework.toDouble(),
        'quiz': request.quiz.toDouble(),
        'exam': request.exam.toDouble(),
      });
      return PredictionResult.fromJson(response.data);
    } on DioException catch (e) {
      print('$tag Predict error [${e.response?.statusCode}]: ${e.response?.data}');
      throw Exception(_getErrorMessage(e));
    }
  }

  /// Ko'p o'quvchi uchun batch prognoz — POST /api/v1/predict/batch/
  /// studentIds: [1, 2, 3, ...]
  Future<List<PredictionResult>> batchPredict(List<int> studentIds) async {
    try {
      print('$tag Batch predict: ${studentIds.length} ta o\'quvchi');
      final response = await _dio.post('predict/batch/',
          data: {'student_ids': studentIds});

      final List list = _parseListResponse(response.data);
      final results = <PredictionResult>[];

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          // Xatolik bo'lgan o'quvchilarni o'tkazib yuboramiz
          if (item.containsKey('error')) {
            print('$tag Batch predict skip: ${item['student_name']} — ${item['error']}');
            continue;
          }
          try {
            results.add(PredictionResult.fromJson(item));
          } catch (e) {
            print('$tag Batch predict parse error: $e');
          }
        }
      }
      print('$tag Batch predict done: ${results.length} natija');
      return results;
    } on DioException catch (e) {
      print('$tag Batch predict error [${e.response?.statusCode}]: ${e.response?.data}');
      throw Exception(_getErrorMessage(e));
    }
  }

  // ══════════════════════════════════════════════════════════
  //  STATISTIKA — faqat o'qituvchiga tegishli
  //  Backend: teacher = request.user bo'yicha filter
  // ══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getOverviewStats() async {
    try {
      final response = await _dio.get('stats/overview/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  /// Xavf ostidagi o'quvchilar — faqat teacher ga tegishlilar
  Future<List<StudentModel>> getAtRiskStudents() async {
    try {
      final response = await _dio.get('stats/at-risk/');
      final List list = _parseListResponse(response.data);
      return list.map((e) {
        // Backend at-risk response: {student_id, student_name, group_name, course_name, ...}
        final studentData = <String, dynamic>{
          'id': e['student_id'] ?? 0,
          'name': e['student_name'] ?? '',
          'group_id': 0,
          'group_name': e['group_name'] ?? '',
          'course_id': 0,
          'course_name': e['course_name'] ?? '',
          'scores': {
            'attendance': 0,
            'homework': 0,
            'quiz': 0,
            'exam': (e['predicted_score'] ?? 0).toDouble(),
          },
          'enrolled_at': null,
        };
        return StudentModel.fromJson(studentData);
      }).toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getCourseStats(int courseId) async {
    try {
      final response = await _dio.get('stats/courses/$courseId/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getGroupStats(int groupId) async {
    try {
      final response = await _dio.get('stats/groups/$groupId/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ══════════════════════════════════════════════════════════
  //  BILDIRISHNOMALAR (fallback)
  // ══════════════════════════════════════════════════════════
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get('notifications/');
      final List list = _parseListResponse(response.data);
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _generateNotificationsFromAtRisk();
      }
      rethrow;
    }
  }

  Future<List<NotificationModel>> _generateNotificationsFromAtRisk() async {
    final atRiskStudents = await getAtRiskStudents();
    return atRiskStudents.map((student) => NotificationModel(
          id: student.id,
          title: 'Xavf ostidagi o\'quvchi',
          message: '${student.name} — darhol yordam kerak!',
          type: NotificationType.atRisk,
          isRead: false,
          createdAt: DateTime.now(),
          studentId: student.id,
          groupId: student.groupId,
          courseId: student.courseId,
        )).toList();
  }
}
