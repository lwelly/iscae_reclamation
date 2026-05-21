import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/utils/api_response_message.dart';
import '../models/semestre_model.dart';
import '../models/note_model.dart';
import '../models/notification_model.dart';
import '../models/profile_model.dart';
import '../models/module_model.dart';
import '../models/document_model.dart';
import '../models/dashboard_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/url_resolver.dart';

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
    final result = await getSemestresWithNiveau();
    return result.semestres;
  }

  Future<SemestresLoadResult> getSemestresWithNiveau() async {
    try {
      final response = await _dio.get(ApiEndpoints.semestres);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final semestres = data.map((json) => SemestreModel.fromJson(json)).toList();
        final niveau = response.data['niveau']?.toString() ?? '';
        return SemestresLoadResult(semestres: semestres, niveau: niveau);
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
        final raw = response.data['data'];
        final List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List;
        } else {
          list = [];
        }
        return list
            .whereType<Map>()
            .map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
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

  // Modifié : accepte maintenant un identifiant String (UUID)
  Future<void> markNotificationAsRead(String id) async {
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

  // Modifié : accepte maintenant un identifiant String (UUID)
  Future<void> deleteNotification(String id) async {
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
      final body = response.data;
      if (response.statusCode == 200 && body is Map && body['success'] == true) {
        final parsed = _parseProfilePayload(body['data']);
        if (parsed != null) return parsed;
      }
      throw Exception(_apiErrorMessage(body, 'Impossible de charger le profil'));
    } on DioException catch (e) {
      throw Exception(_apiErrorMessage(e.response?.data, e.message ?? 'Erreur réseau'));
    }
  }

  ProfileModel? _parseProfilePayload(dynamic payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);

    // { data: { user... } } déjà extrait par l'appelant — sinon imbriqué
    if (map['user'] is Map) {
      return ProfileModel.fromJson(Map<String, dynamic>.from(map['user'] as Map));
    }
    if (map['student'] is Map && map['email'] == null && map['id'] == null) {
      return ProfileModel.fromJson(Map<String, dynamic>.from(map['student'] as Map));
    }

    return ProfileModel.fromJson(map);
  }

  /// Aligné sur ProfileView.vue : photo_url / photo_path dans data ou à la racine.
  ProfileModel _applyPhotoFromUploadResponse(ProfileModel base, dynamic body) {
    if (body is! Map) return base;

    final root = Map<String, dynamic>.from(body);
    final data = root['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final student = dataMap['student'] is Map ? Map<String, dynamic>.from(dataMap['student'] as Map) : dataMap;

    String? pick(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
      return null;
    }

    var url = pick(student, ['photo_url', 'photoUrl']) ??
        pick(dataMap, ['photo_url', 'photoUrl']) ??
        pick(root, ['photo_url', 'photoUrl']);

    var path = pick(student, ['photo_path', 'photoPath', 'photo']) ??
        pick(dataMap, ['photo_path', 'photoPath', 'photo']) ??
        pick(root, ['photo_path', 'photoPath', 'photo']);

    // Comme ProfileView.vue : chemin relatif peut être dans photo_url
    if (url != null && path == null && !url.startsWith('http')) {
      path = url;
      url = null;
    }

    if (url != null || path != null) {
      final built = resolveProfilePhoto(photoUrl: url, photoPath: path);
      return base.copyWith(
        photoUrl: url?.startsWith('http') == true ? url : (built.isNotEmpty ? built : url),
        photoPath: path ?? url,
      );
    }

    final parsed = _parseProfilePayload(data ?? root);
    if (parsed != null && parsed.hasPhoto) return base.withPhotoFrom(parsed);
    return base;
  }

  String _apiErrorMessage(dynamic body, String fallback) => extractApiMessage(body, fallback);

  String _safePhotoFileName(String? fileName) {
    var name = (fileName ?? 'photo.jpg').trim();
    if (!name.contains('.')) name = '$name.jpg';
    return name;
  }

  MediaType _photoMediaType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<MultipartFile> _buildPhotoMultipart({
    String? filePath,
    List<int>? bytes,
    String? fileName,
  }) async {
    final safeName = _safePhotoFileName(fileName);
    final type = _photoMediaType(safeName);
    if (bytes != null && bytes.isNotEmpty) {
      return MultipartFile.fromBytes(bytes, filename: safeName, contentType: type);
    }
    if (filePath != null && filePath.isNotEmpty) {
      return MultipartFile.fromFile(filePath, filename: safeName, contentType: type);
    }
    throw Exception('Fichier photo introuvable');
  }

  // ... (Le reste du fichier concernant les modules et documents reste identique)
  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.profile, data: data);
      final body = response.data;
      if (response.statusCode == 200 && body is Map && body['success'] == true) {
        final parsed = _parseProfilePayload(body['data']);
        if (parsed != null) return parsed;
        return getProfile();
      }
      throw Exception(_apiErrorMessage(body, 'Échec de la mise à jour du profil'));
    } on DioException catch (e) {
      throw Exception(_apiErrorMessage(e.response?.data, e.message ?? 'Erreur réseau'));
    }
  }

  Future<ProfileModel> updateProfilePhoto({
    String? filePath,
    List<int>? bytes,
    String? fileName,
    ProfileModel? currentProfile,
  }) async {
    try {
      final file = await _buildPhotoMultipart(filePath: filePath, bytes: bytes, fileName: fileName);
      final formData = FormData.fromMap({'photo': file});

      // Comme ProfileView.vue : POST multipart, champ « photo », sans Content-Type forcé
      final response = await _dio.post(
        ApiEndpoints.profilePhoto,
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final body = response.data;
      if (!isApiSuccess(body, response.statusCode)) {
        throw Exception(_apiErrorMessage(body, 'Échec de la mise à jour de la photo'));
      }

      final base = currentProfile ?? await getProfile();
      var merged = _applyPhotoFromUploadResponse(base, body);
      if (!merged.hasPhoto) {
        try {
          final reloaded = await getProfile();
          merged = reloaded.withPhotoFrom(merged).mergePhotoFrom(base);
        } catch (_) {}
      }
      return merged;
    } on DioException catch (e) {
      throw Exception(_apiErrorMessage(e.response?.data, e.message ?? 'Erreur réseau'));
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.profilePassword,
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update password');
      }
    } on DioException catch (e) {
      throw Exception('Error updating password: ${e.message}');
    }
  }

  Future<List<ModuleModel>> getModules({int? semestreId}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.modules,
        queryParameters: semestreId != null ? {'semestre_id': semestreId} : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final raw = response.data['data'];
        final List<dynamic> data;
        if (raw is List) {
          data = raw;
        } else if (raw is Map && raw['modules'] is List) {
          data = raw['modules'] as List;
        } else {
          data = [];
        }
        return data
            .whereType<Map>()
            .map((json) => ModuleModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      final message = response.data['message']?.toString();
      throw Exception(message ?? 'Failed to load modules');
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      throw Exception(message ?? e.message ?? 'Error loading modules');
    }
  }

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