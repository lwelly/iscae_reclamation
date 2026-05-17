import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/reclamation_model.dart';
import '../../core/constants/api_endpoints.dart';

class ReclamationService {
  final ApiClient _apiClient;

  ReclamationService(this._apiClient);

  // ══════════════════════════════════════════════════════════════════
  // جلب كل شكاوى الطالب وتحويلها تلقائياً إلى قائمة كائنات جاهزة للعرض
  // ══════════════════════════════════════════════════════════════════
  Future<List<ReclamationModel>?> getMyReclamations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.reclamations);

      // التأكد من أن الرد ليس null وأن محتوى البيانات عبارة عن Map
      if (response != null && response.data is Map) {
        final dataMap = response.data as Map<String, dynamic>;

        if (dataMap['success'] == true && dataMap['data'] != null) {
          if (dataMap['data'] is List) {
            List<dynamic> dataList = dataMap['data'];
            return dataList.map((json) => ReclamationModel.fromJson(json)).toList();
          }
        }
      }
    } on DioException catch (e) {
      print("خطأ سيرفر لارفيل عند جلب الشكاوى: ${e.response?.data}");
    } catch (e) {
      print("خطأ غير متوقع عند جلب الشكاوى: $e");
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════
  // إرسال شكوى جديدة بناءً على الحقول المطلوبة في الـ Migration
  // ══════════════════════════════════════════════════════════════════
  Future<bool> sendNewReclamation(ReclamationModel reclamation) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.reclamations,
        data: reclamation.toJson(),
      );

      // التحقق الآمن من أن الرد غير فارغ ومن بنية الـ Map المرتجعة
      if (response != null && response.data is Map) {
        final dataMap = response.data as Map<String, dynamic>;
        return dataMap['success'] == true;
      }

      return false;
    } on DioException catch (e) {
      print("فشل إرسال الشكوى: ${e.response?.data}");
      return false;
    } catch (e) {
      print("خطأ غير متوقع عند إرسال الشكوى: $e");
      return false;
    }
  }
}