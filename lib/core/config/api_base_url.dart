import 'package:flutter/foundation.dart';

/// URL de base de l'API Laravel.
///
/// Surcharge possible au lancement :
/// `flutter run --dart-define=API_BASE_URL=http://192.168.100.59:8000/api/v1`
class ApiBaseUrl {
  /// IP LAN du serveur (téléphone physique sur le même réseau Wi‑Fi).
  static const lanHost = 'http://192.168.100.59:8000/api/v1';

  /// Machine locale (Flutter Web / émulateur sur le PC qui héberge Laravel).
  static const localHost = 'http://127.0.0.1:8000/api/v1';

  static String get value {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return localHost;

    return lanHost;
  }
}
