import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_error_message.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // ══════════════════════════════════════════════════════════════════
  // دالة تسجيل الدخول القياسية
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> login({
    required String login,
    required String password,
    required String deviceFingerprint,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'login': login,
          'password': password,
          'device_fingerprint': deviceFingerprint,
        },
      );
      if (response != null && response.data is Map) return response.data;
      return 'استجابة غير معرّفة من السيرفر';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return formatApiError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // دالة التحقق من الرمز (OTP) للجهاز الجديد
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> verifyDeviceOtp({
    required int userId,
    required String otpCode,
    required String deviceFingerprint,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-device-otp',
        data: {
          'user_id': userId,
          'otp_code': otpCode,
          'device_fingerprint': deviceFingerprint,
        },
      );
      if (response != null && response.data is Map) return response.data;
      return 'استجابة غير صالحة';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return formatApiError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 1. التحقق من الهوية الأكاديمية (الخطوة الأولى في التسجيل)
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> verifyIdentity({
    required String matricule,
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyIdentity,
        data: {'matricule': matricule, 'email': email},
      );
      if (response != null && response.data is Map) return response.data;
      return 'بيانات الاستجابة غير صالحة';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'حدث خطأ أثناء الاتصال بالسيرفر';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 2. طلب إرسال كود الـ OTP للتسجيل الجديد
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> sendRegistrationOtp({
    required int studentId,
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendOtp,
        data: {
          'student_id': studentId,
          'email': email.trim().toLowerCase(),
        },
      );
      if (response != null && response.data is Map) return response.data;
      return 'فشل إرسال كود التحقق';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'خطأ أثناء طلب الرمز من الشبكة';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 3. التحقق من صحة كود الـ OTP المدخل للتسجيل
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> verifyRegistrationOtp({
    required int studentId,
    required String otpCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {'student_id': studentId, 'otp_code': otpCode},
      );
      if (response != null && response.data is Map) return response.data;
      return 'فشل فحص رمز التأكيد';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'الرمز منتهي أو غير صحيح';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 4. إنشاء وتأكيد الحساب النهائي للطالب
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> registerStudent({
    required int studentId,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'student_id': studentId,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response != null && response.data is Map) return response.data;
      return 'فشل إتمام عملية التسجيل الأكاديمي';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'حدث خطأ غير متوقع أثناء إرسال البيانات';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // دالات استعادة كلمة المرور (Forgot Password Flow)
  // ══════════════════════════════════════════════════════════════════
  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post('/auth/forgot-password', data: {'email': email});
      if (response != null && response.data is Map) return response.data;
      return 'استجابة غير صالحة';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'خطأ اتصال بالشبكة';
    }
  }

  Future<dynamic> forgotVerifyOtp(int userId, String otpCode) async {
    try {
      final response = await _apiClient.post('/auth/forgot-password/verify-otp', data: {'user_id': userId, 'otp_code': otpCode});
      if (response != null && response.data is Map) return response.data;
      return 'استجابة غير صالحة';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'خطأ أثناء التحقق';
    }
  }

  Future<dynamic> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post('/auth/reset-password', data: {
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      if (response != null && response.data is Map) return response.data;
      return 'فشل تحديث كلمة المرور';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) return e.response?.data;
      return 'خطأ أثناء تحديث البيانات';
    }
  }
}