import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';

class ApiClient {
  final Dio _dio = Dio();
  String? _authToken;

  ApiClient() {
    // الاعتماد الكلي على الروابط الموحدة من كلاس الـ Endpoints مباشرة منعاً للتشتت
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            print("غير مصرح به - يجب إعادة تسجيل الدخول");
          }
          return handler.next(e);
        },
      ),
    );
  }

  void setToken(String token) {
    _authToken = token;
  }

  Future<Response?> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  Future<Response?> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException {
      rethrow;
    }
  }

  Future<Response?> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException {
      rethrow;
    }
  }

  Future<Response?> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException {
      rethrow;
    }
  }
}