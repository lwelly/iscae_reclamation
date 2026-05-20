/// Extrait un message lisible depuis une réponse API Laravel.
String extractApiMessage(dynamic body, [String fallback = 'Erreur serveur']) {
  if (body is! Map) return fallback;

  final message = body['message'];
  if (message != null && message.toString().isNotEmpty) {
    return message.toString();
  }

  final errors = body['errors'];
  if (errors is Map) {
    final parts = <String>[];
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        parts.add(value.first.toString());
      } else if (value != null) {
        parts.add(value.toString());
      }
    }
    if (parts.isNotEmpty) return parts.join('\n');
  }

  return fallback;
}

bool isApiSuccess(dynamic body, int? statusCode) {
  if (statusCode != null && statusCode >= 200 && statusCode < 300) {
    if (body is Map && body.containsKey('success')) {
      return body['success'] == true;
    }
    return true;
  }
  return false;
}
