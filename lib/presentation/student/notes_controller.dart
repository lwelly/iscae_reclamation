import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';
import '../../../core/config/api_config.dart';

class NotesController extends ChangeNotifier {
  List<NoteModel> _notes = [];
  NoteModel? _selectedNote;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int? _selectedSemestreId;

  // Getters
  List<NoteModel> get notes => _notes;
  NoteModel? get selectedNote => _selectedNote;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  int? get selectedSemestreId => _selectedSemestreId;

  // Charger les notes
  Future<void> loadNotes({int? semestreId}) async {
    _setLoading(true);
    _hasError = false;
    _errorMessage = null;
    _selectedSemestreId = semestreId;

    try {
      _notes = await ApiConfig().studentService.getNotes(
        semestreId: semestreId,
      );
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Charger une note spécifique
  Future<void> loadNoteById(int id) async {
    _setLoading(true);
    try {
      _selectedNote = await ApiConfig().studentService.getNoteById(id);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Filtrer les notes par type
  List<NoteModel> getNotesByType(String type) {
    return _notes.where((note) => note.type == type).toList();
  }

  // Calculer la moyenne pour un semestre
  double? calculateMoyenne({int? semestreId}) {
    final filteredNotes = semestreId != null
        ? _notes.where((note) => note.semestreCode?.contains(semestreId.toString()) ?? false).toList()
        : _notes;

    if (filteredNotes.isEmpty) return null;

    double total = 0;
    double totalCoeff = 0;

    for (var note in filteredNotes) {
      if (note.value != null && note.coefficient != null) {
        total += note.value! * note.coefficient!;
        totalCoeff += note.coefficient!;
      }
    }

    return totalCoeff > 0 ? total / totalCoeff : null;
  }

  // Obtenir les notes par semestre
  Map<String, List<NoteModel>> getNotesBySemestre() {
    final Map<String, List<NoteModel>> grouped = {};
    for (var note in _notes) {
      final semestre = note.semestreCode ?? 'Non défini';
      if (!grouped.containsKey(semestre)) {
        grouped[semestre] = [];
      }
      grouped[semestre]!.add(note);
    }
    return grouped;
  }

  // Obtenir les notes par module
  Map<String, List<NoteModel>> getNotesByModule() {
    final Map<String, List<NoteModel>> grouped = {};
    for (var note in _notes) {
      final module = note.moduleName ?? 'Non défini';
      if (!grouped.containsKey(module)) {
        grouped[module] = [];
      }
      grouped[module]!.add(note);
    }
    return grouped;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedNote() {
    _selectedNote = null;
    notifyListeners();
  }
}
