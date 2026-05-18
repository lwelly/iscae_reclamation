import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/reclamation_model.dart';
import '../../core/config/api_config.dart';

class ReclamationController extends ChangeNotifier {
  List<ReclamationModel> _reclamations = [];
  ReclamationModel? _selectedReclamation;
  bool _isLoading = false;
  String? _errorMessage;

  List<ReclamationModel> get reclamations => _reclamations;
  ReclamationModel? get selectedReclamation => _selectedReclamation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReclamations({String? status, String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reclamations = await ApiConfig().reclamationService.getReclamations(
        status: status,
        type: type,
      );
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedReclamation = await ApiConfig().reclamationService.getReclamationById(id);
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReclamation({
    required String semestreId,
    required String moduleId,
    required String type,
    required double noteActuelle,
    double? noteReclamee,
    required String justification,
    File? file,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await ApiConfig().reclamationService.createReclamation(
        semestreId: semestreId,
        moduleId: moduleId,
        type: type,
        noteActuelle: noteActuelle,
        noteReclamee: noteReclamee,
        justification: justification,
        file: file,
      );
      if (success) {
        await fetchReclamations();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelReclamation(int id) async {
    try {
      final success = await ApiConfig().reclamationService.cancelReclamation(id);
      if (success) {
        _reclamations.removeWhere((element) => element.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Helper pour rendre les messages d'erreurs lisibles à l'écran sans le texte "Exception:"
  String _cleanErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.replaceFirst('Exception: ', '');
    }
    return msg;
  }
}