import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/utils/api_error_message.dart';
import '../../../data/models/reclamation_model.dart';

class ProfileRecStats {
  final int total;
  final int pending;
  final int resolved;

  const ProfileRecStats({
    this.total = 0,
    this.pending = 0,
    this.resolved = 0,
  });
}

class ProfileController extends ChangeNotifier {
  static const _prefPhotoUrl = 'profile_photo_url';
  static const _prefPhotoPath = 'profile_photo_path';

  ProfileModel? _profile;
  ProfileRecStats _recStats = const ProfileRecStats();
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _uploadingPhoto = false;
  bool _hasError = false;
  String? _errorMessage;

  ProfileModel? get profile => _profile;
  ProfileRecStats get recStats => _recStats;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get uploadingPhoto => _uploadingPhoto;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _setLoading(true);
    _hasError = false;
    _errorMessage = null;

    try {
      final results = await Future.wait([
        ApiConfig().studentService.getProfile(),
        ApiConfig().reclamationService.getReclamations().catchError((_) => <ReclamationModel>[]),
      ]);
      var loaded = results[0] as ProfileModel;
      loaded = await _applyCachedPhoto(loaded);
      _profile = loaded.mergePhotoFrom(_profile);
      final recs = results[1] as List<ReclamationModel>;
      _recStats = ProfileRecStats(
        total: recs.length,
        pending: recs
            .where((r) => ['submitted', 'received', 'in_review', 'escalated'].contains(r.status))
            .length,
        resolved: recs.where((r) => r.status == 'resolved').length,
      );
      _setLoading(false);
    } catch (e) {
      _setError(_formatError(e));
    }
  }

  Future<bool> updateProfile({
    String? prenom,
    String? nom,
    String? email,
    String? phone,
    String? dateNaissance,
    String? lieuNaissance,
    String? nationalite,
    String? adresse,
  }) async {
    _setUpdating(true);
    _hasError = false;
    _errorMessage = null;

    try {
      final data = <String, dynamic>{};
      if (prenom != null && prenom.isNotEmpty) data['prenom'] = prenom;
      if (nom != null && nom.isNotEmpty) data['nom'] = nom;
      if (email != null && email.isNotEmpty) data['email'] = email;
      data['phone'] = phone?.isNotEmpty == true ? phone : null;
      data['date_naissance'] = dateNaissance?.isNotEmpty == true ? dateNaissance : null;
      data['lieu_naissance'] = lieuNaissance?.isNotEmpty == true ? lieuNaissance : null;
      data['nationalite'] = nationalite?.isNotEmpty == true ? nationalite : null;
      data['adresse'] = adresse?.isNotEmpty == true ? adresse : null;

      await ApiConfig().studentService.updateProfile(data);
      await loadProfile();
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError(_formatError(e));
      return false;
    }
  }

  Future<bool> updatePhoto({
    String? path,
    List<int>? bytes,
    String? fileName,
  }) async {
    _uploadingPhoto = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final base = _profile ?? await ApiConfig().studentService.getProfile();
      final updated = await ApiConfig().studentService.updateProfilePhoto(
        filePath: path,
        bytes: bytes,
        fileName: fileName,
        currentProfile: base,
      );
      _profile = base.withPhotoFrom(updated);
      if (_profile!.hasPhoto) {
        await _cachePhoto(_profile!);
      } else {
        throw Exception('Photo envoyée mais le serveur n\'a pas renvoyé d\'URL. Réessayez.');
      }
      _uploadingPhoto = false;
      notifyListeners();
      _softReloadProfile();
      return true;
    } catch (e) {
      _uploadingPhoto = false;
      _errorMessage = _formatError(e);
      _hasError = true;
      notifyListeners();
      return false;
    }
  }

  /// Recharge le profil sans spinner, en conservant la photo.
  Future<void> _softReloadProfile() async {
    try {
      final keep = _profile;
      final loaded = await ApiConfig().studentService.getProfile();
      var merged = loaded.mergePhotoFrom(keep);
      merged = await _applyCachedPhoto(merged);
      _profile = merged;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setUpdating(true);
    _hasError = false;
    _errorMessage = null;

    try {
      await ApiConfig().studentService.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError(_formatError(e));
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUpdating(bool value) {
    _isUpdating = value;
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _isUpdating = false;
    _uploadingPhoto = false;
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  String _formatError(Object e) => formatApiError(e);

  Future<void> _cachePhoto(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
      await prefs.setString(_prefPhotoUrl, profile.photoUrl!);
    }
    if (profile.photoPath != null && profile.photoPath!.isNotEmpty) {
      await prefs.setString(_prefPhotoPath, profile.photoPath!);
    }
  }

  Future<ProfileModel> _applyCachedPhoto(ProfileModel profile) async {
    if (profile.hasPhoto) return profile;
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_prefPhotoUrl);
    final path = prefs.getString(_prefPhotoPath);
    if ((url == null || url.isEmpty) && (path == null || path.isEmpty)) {
      return profile;
    }
    return profile.copyWith(photoUrl: url, photoPath: path);
  }
}
