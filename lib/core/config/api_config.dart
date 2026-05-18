import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../../data/services/api_client.dart';
import '../../data/services/student_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/reclamation_service.dart'; // <-- ÉTAPE 1 : Vérifiez que ce chemin est exact

class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  late final ApiClient _apiClient;
  late final StudentService _studentService;
  late final AuthService _authService;
  late final ReclamationService _reclamationService; // <-- ÉTAPE 2 : Déclaration de la variable privée
  late final Dio _studentDio;
  String? _authToken;

  ApiClient get apiClient => _apiClient;
  StudentService get studentService => _studentService;
  AuthService get authService => _authService;

  // ÉTAPE 3 : Le getter explicite qui posait problème
  ReclamationService get reclamationService => _reclamationService;

  void initialize({String? authToken}) {
    _authToken = authToken;
    _apiClient = ApiClient();
    if (authToken != null) {
      _apiClient.setToken(authToken);
    }

    // Initialiser AuthService avec ApiClient
    _authService = AuthService(_apiClient);

    // Créer une instance Dio pour les services
    _studentDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Ajouter l'intercepteur pour le token
    _studentDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
    ));

    _studentService = StudentService(_studentDio);

    // ÉTAPE 4 : Initialisation obligatoire pour éviter une erreur "LateInitializationError"
    _reclamationService = ReclamationService(_studentDio);
  }

  void setAuthToken(String token) {
    _authToken = token;
    _apiClient.setToken(token);
  }

  void clearAuthToken() {
    _authToken = null;
    _apiClient.setToken('');
  }
}