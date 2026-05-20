import 'package:dio/dio.dart';
import '../config/api_base_url.dart';
import 'api_response_message.dart';

/// Message d'erreur lisible pour l'utilisateur (français).
String formatApiError(Object error) {
  if (error is DioException) {
    final base = ApiBaseUrl.value;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Délai dépassé : le serveur ne répond pas.\n'
            'Vérifiez que Laravel tourne (php artisan serve) et l\'URL :\n$base';
      case DioExceptionType.connectionError:
        return 'Connexion impossible au serveur.\n'
            'Vérifiez le Wi‑Fi et que l\'API est accessible :\n$base';
      case DioExceptionType.badResponse:
        return extractApiMessage(
          error.response?.data,
          'Erreur serveur (${error.response?.statusCode ?? '?'})',
        );
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      default:
        return error.message ?? 'Erreur réseau.';
    }
  }

  final msg = error.toString();
  const prefix = 'Exception: ';
  return msg.startsWith(prefix) ? msg.substring(prefix.length) : msg;
}
