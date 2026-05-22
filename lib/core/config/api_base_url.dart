import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// URL de base de l'API Laravel.
///
/// Surcharge au lancement : `flutter run --dart-define=API_BASE_URL=http://IP:8000/api/v1`
/// Ou dans l'app : écran de connexion → « Configurer le serveur ».
class ApiBaseUrl {
  static const _prefKey = 'api_base_url';

  /// IP LAN du serveur (Wi‑Fi maison, même réseau que le PC).
  static const lanHost = 'http://192.168.100.59:8000/api/v1';

  /// Machine locale (Flutter Web / émulateur sur le PC).
  static const localHost = 'http://127.0.0.1:8000/api/v1';

  static String? _savedOverride;

  /// Charge l'URL enregistrée (à appeler au démarrage).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _savedOverride = saved != null && saved.trim().isNotEmpty ? normalize(saved) : null;
  }

  /// Enregistre une URL personnalisée (point d'accès mobile, autre réseau).
  static Future<void> save(String url) async {
    final normalized = normalize(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, normalized);
    _savedOverride = normalized;
  }

  /// Réinitialise l'URL par défaut automatique.
  static Future<void> clearOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _savedOverride = null;
  }

  static String get value {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return normalize(fromEnv);
    if (_savedOverride != null && _savedOverride!.isNotEmpty) return _savedOverride!;
    if (kIsWeb) return localHost;
    return lanHost;
  }

  static String get defaultForPlatform {
    if (kIsWeb) return localHost;
    return lanHost;
  }

  /// Normalise : ajoute http:// si besoin et le suffixe /api/v1.
  static String normalize(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return defaultForPlatform;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    u = u.replaceAll(RegExp(r'/+$'), '');
    if (!u.endsWith('/api/v1')) {
      if (u.contains('/api/')) {
        final idx = u.indexOf('/api/');
        u = u.substring(0, idx);
      }
      u = '$u/api/v1';
    }
    return u;
  }
}
