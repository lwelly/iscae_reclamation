import '../constants/api_endpoints.dart';

/// Résout les URLs relatives renvoyées par l'API (storage, photos) vers l'origine du serveur.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final origin = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  if (url.startsWith('http://') || url.startsWith('https://')) {
    final uri = Uri.tryParse(url);
    final base = Uri.parse(origin);
    if (uri != null && uri.host != base.host) {
      return uri.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
    }
    return url;
  }
  if (url.startsWith('/')) return '$origin$url';
  return '$origin/$url';
}

/// URL photo de profil (photo_url ou chemin storage).
String resolveProfilePhoto({String? photoUrl, String? photoPath}) {
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return resolveMediaUrl(photoUrl);
  }
  if (photoPath == null || photoPath.isEmpty) return '';
  if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
    return resolveMediaUrl(photoPath);
  }
  final origin = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  var path = photoPath.replaceFirst(RegExp(r'^/'), '');
  if (path.startsWith('storage/')) return '$origin/$path';
  if (path.startsWith('public/')) return '$origin/${path.replaceFirst('public/', '')}';
  // Chemin Laravel fréquent : students/xxx.jpg ou photos/xxx.jpg
  return '$origin/storage/$path';
}
