import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/url_resolver.dart';

/// Avatar profil avec initiales, image réseau ou fichier local.
class ProfileAvatar extends StatelessWidget {
  final double radius;
  final String initials;
  final Color backgroundColor;
  final String? photoUrl;
  final String? photoPath;
  final String? localFilePath;
  final Uint8List? localBytes;
  /// Incrémenter après upload pour forcer le rechargement de l'image réseau.
  final int? cacheBust;

  const ProfileAvatar({
    super.key,
    required this.radius,
    required this.initials,
    required this.backgroundColor,
    this.photoUrl,
    this.photoPath,
    this.localFilePath,
    this.localBytes,
    this.cacheBust,
  });

  String? get _resolvedUrl {
    final url = resolveProfilePhoto(photoUrl: photoUrl, photoPath: photoPath);
    return url.isEmpty ? null : url;
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    Widget child;
    if (localBytes != null) {
      child = Image.memory(localBytes!, width: size, height: size, fit: BoxFit.cover);
    } else if (localFilePath != null && !kIsWeb) {
      child = Image.file(File(localFilePath!), width: size, height: size, fit: BoxFit.cover);
    } else if (_resolvedUrl != null) {
      var networkUrl = _resolvedUrl!;
      if (cacheBust != null) {
        networkUrl = networkUrl.contains('?') ? '$networkUrl&v=$cacheBust' : '$networkUrl?t=$cacheBust';
      }
      child = Image.network(
        networkUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(),
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return Center(
            child: SizedBox(
              width: radius * 0.6,
              height: radius * 0.6,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.9)),
            ),
          );
        },
      );
    } else {
      child = _initials();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(child: child),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.56,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
