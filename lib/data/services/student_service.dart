import 'package:dio/dio.dart';
import '../models/semestre_model.dart';
import '../models/note_model.dart';
import '../models/notification_model.dart';
import '../models/profile_model.dart';
import '../models/module_model.dart';
import '../models/document_model.dart';
import '../models/dashboard_model.dart';
import '../../core/constants/api_endpoints.dart';

class StudentService {
  final Dio _dio;

  StudentService(this._dio);

  // ── Dashboard ──────────────────────────────────────────────
  Future<DashboardModel> getDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboard);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DashboardModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to load dashboard');
    } on DioException catch (e) {
      throw Exception('Error loading dashboard: ${e.message}');
    }
  }

  // ── Semestres ──────────────────────────────────────────────
  Future<List<SemestreModel>> getSemestres() async {
    try {
      final response = await _dio.get(ApiEndpoints.semestres);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => SemestreModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load semestres');
    } on DioException catch (e) {
      throw Exception('Error loading semestres: ${e.message}');
    }
  }

  // ── Notes ──────────────────────────────────────────────
  Future<List<NoteModel>> getNotes({int? semestreId}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notes,
        queryParameters: semestreId != null ? {'semestre_id': semestreId} : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => NoteModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load notes');
    } on DioException catch (e) {
      throw Exception('Error loading notes: ${e.message}');
    }
  }

  Future<NoteModel> getNoteById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.showNote(id));
      if (response.statusCode == 200 && response.data['success'] == true) {
        return NoteModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to load note');
    } on DioException catch (e) {
      throw Exception('Error loading note: ${e.message}');
    }
  }

  // ── Notifications ──────────────────────────────────────────────
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load notifications');
    } on DioException catch (e) {
      throw Exception('Error loading notifications: ${e.message}');
    }
  }

  Future<Map<String, int>> getNotificationCounts() async {
    try {
      final response = await _dio.get(ApiEndpoints.notificationCounts);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, int>.from(response.data['data']);
      }
      throw Exception('Failed to load notification counts');
    } on DioException catch (e) {
      throw Exception('Error loading notification counts: ${e.message}');
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    try {
      final response = await _dio.put(ApiEndpoints.readNotification(id));
      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } on DioException catch (e) {
      throw Exception('Error marking notification as read: ${e.message}');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await _dio.put(ApiEndpoints.readAllNotifications);
      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } on DioException catch (e) {
      throw Exception('Error marking all notifications as read: ${e.message}');
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      final response = await _dio.delete(ApiEndpoints.deleteNotification(id));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } on DioException catch (e) {
      throw Exception('Error deleting notification: ${e.message}');
    }
  }

  // ── Profile ──────────────────────────────────────────────
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProfileModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to load profile');
    } on DioException catch (e) {
      throw Exception('Error loading profile: ${e.message}');
    }
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.profile, data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProfileModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update profile');
    } on DioException catch (e) {
      throw Exception('Error updating profile: ${e.message}');
    }
  }

  Future<ProfileModel> updateProfilePhoto(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoPath),
      });
      final response = await _dio.post(ApiEndpoints.profilePhoto, data: formData);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProfileModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update profile photo');
    } on DioException catch (e) {
      throw Exception('Error updating profile photo: ${e.message}');
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.profilePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update password');
      }
    } on DioException catch (e) {
      throw Exception('Error updating password: ${e.message}');
    }
  }

  // ── Modules ──────────────────────────────────────────────
  Future<List<ModuleModel>> getModules({int? semestreId}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.modules,
        queryParameters: semestreId != null ? {'semestre_id': semestreId} : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ModuleModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load modules');
    } on DioException catch (e) {
      throw Exception('Error loading modules: ${e.message}');
    }
  }

  // ── Documents ──────────────────────────────────────────────
  Future<List<DocumentModel>> getDocuments({String? category}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.documents,
        queryParameters: category != null ? {'category': category} : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => DocumentModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load documents');
    } on DioException catch (e) {
      throw Exception('Error loading documents: ${e.message}');
    }
  }

  Future<DocumentModel> getDocumentById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.showDocument(id));
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to load document');
    } on DioException catch (e) {
      throw Exception('Error loading document: ${e.message}');
    }
  }
}
