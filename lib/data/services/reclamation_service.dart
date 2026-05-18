import 'dart:io';
import 'package:dio/dio.dart'; // <-- Ce package sera reconnu après le 'flutter pub add'
import '../models/reclamation_model.dart';
import '../../core/constants/api_endpoints.dart';

class ReclamationService {
  final Dio _dio; // Reçu depuis ApiConfig

  ReclamationService(this._dio);

  // GET /api/v1/student/reclamations
  Future<List<ReclamationModel>> getReclamations({String? status, String? type}) async {
    final queryParameters = <String, dynamic>{};
    if (status != null && status != 'all') queryParameters['status'] = status;
    if (type != null) queryParameters['type'] = type;

    final Response response = await _dio.get(
      ApiEndpoints.reclamations,
      queryParameters: queryParameters,
    );

    if (response.data != null && response.data['success'] == true) {
      final List list = response.data['data'] ?? [];
      return list.map((json) => ReclamationModel.fromJson(json)).toList();
    }
    throw Exception(response.data?['message'] ?? 'Erreur lors du chargement des réclamations');
  }

  // GET /api/v1/student/reclamations/{id}
  Future<ReclamationModel> getReclamationById(int id) async {
    final Response response = await _dio.get(ApiEndpoints.showReclamation(id));

    if (response.data != null && response.data['success'] == true) {
      return ReclamationModel.fromJson(response.data['data']);
    }
    throw Exception(response.data?['message'] ?? 'Détails introuvables');
  }

  // POST /api/v1/student/reclamations
  Future<bool> createReclamation({
    required String semestreId,
    required String moduleId,
    required String type,
    required double noteActuelle,
    double? noteReclamee,
    required String justification,
    File? file,
  }) async {
    final formData = FormData.fromMap({
      'semestre_id': int.parse(semestreId),
      'module_id': int.parse(moduleId),
      'type': type,
      'note_actuelle': noteActuelle,
      if (noteReclamee != null) 'note_reclamee': noteReclamee,
      'justification': justification,
      if (file != null)
        'document': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
    });

    final Response response = await _dio.post(
      ApiEndpoints.reclamations,
      data: formData,
    );

    return response.data != null && response.data['success'] == true;
  }

  // DELETE /api/v1/student/reclamations/{id}
  Future<bool> cancelReclamation(int id) async {
    final Response response = await _dio.delete(ApiEndpoints.updateReclamation(id));
    return response.data != null && response.data['success'] == true;
  }
}