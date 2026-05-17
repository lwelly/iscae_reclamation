import 'package:flutter/material.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/config/api_config.dart';

class ProfileController extends ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _hasError = false;
  String? _errorMessage;

  // Getters
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  // Charger le profil
  Future<void> loadProfile() async {
    _setLoading(true);
    _hasError = false;
    _errorMessage = null;

    try {
      _profile = await ApiConfig().studentService.getProfile();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Mettre à jour le profil
  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    _setUpdating(true);
    _hasError = false;
    _errorMessage = null;

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;

      _profile = await ApiConfig().studentService.updateProfile(data);
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Mettre à jour la photo de profil
  Future<bool> updateProfilePhoto(String photoPath) async {
    _setUpdating(true);
    _hasError = false;
    _errorMessage = null;

    try {
      _profile = await ApiConfig().studentService.updateProfilePhoto(photoPath);
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Changer le mot de passe
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    _setUpdating(true);
    _hasError = false;
    _errorMessage = null;

    try {
      await ApiConfig().studentService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      _setUpdating(false);
      return true;
    } catch (e) {
      _setError(e.toString());
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
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }
}
