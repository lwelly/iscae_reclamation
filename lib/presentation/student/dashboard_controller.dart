import 'package:flutter/material.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/reclamation_model.dart';
import '../../../data/models/semestre_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/config/api_config.dart';

class DashboardController extends ChangeNotifier {
  DashboardModel? _dashboard;
  List<ReclamationModel> _reclamations = [];
  List<SemestreModel> _semestres = [];
  List<NotificationModel> _notifications = [];
  Map<String, int>? _notificationCounts;
  String _studentFirstName = 'Étudiant';

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  static const _dashPendingStatuses = ['submitted', 'in_review', 'escalated'];

  // Getters
  DashboardModel? get dashboard => _dashboard;
  List<ReclamationModel> get reclamations => _reclamations;
  List<SemestreModel> get semestres => _semestres;
  List<NotificationModel> get notifications => _notifications;
  Map<String, int>? get notificationCounts => _notificationCounts;
  String get studentFirstName => _studentFirstName;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  int get totalCount => _reclamations.length;
  int get pendingCount => _reclamations.where((r) => _dashPendingStatuses.contains(r.status)).length;
  int get resolvedCount => _reclamations.where((r) => r.status == 'resolved').length;
  int get rejectedCount => _reclamations.where((r) => r.status == 'rejected').length;

  List<ReclamationModel> get recentReclamations {
    final sorted = [..._reclamations];
    sorted.sort((a, b) {
      try {
        return DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt));
      } catch (_) {
        return 0;
      }
    });
    return sorted.take(6).toList();
  }

  /// Comptage par statut pour le graphique doughnut (aligné Vue).
  Map<String, int> get statusCounts {
    final counts = <String, int>{
      'in_review': 0,
      'resolved': 0,
      'rejected': 0,
      'submitted': 0,
      'escalated': 0,
    };
    for (final r in _reclamations) {
      if (counts.containsKey(r.status)) {
        counts[r.status] = counts[r.status]! + 1;
      }
    }
    return counts;
  }

  // Charger les données du tableau de bord (réclamations + profil)
  Future<void> loadAllData() async {
    _setLoading(true);
    _hasError = false;
    _errorMessage = null;

    try {
      _reclamations = await ApiConfig().reclamationService.getReclamations();
      try {
        final profile = await ApiConfig().studentService.getProfile();
        final name = profile.prenom?.trim().isNotEmpty == true
            ? profile.prenom!
            : profile.fullName.split(' ').first;
        if (name.isNotEmpty) _studentFirstName = name;
      } catch (_) {
        try {
          _dashboard = await ApiConfig().studentService.getDashboard();
          final parts = _dashboard!.studentName.split(' ');
          if (parts.isNotEmpty && parts.first.isNotEmpty) {
            _studentFirstName = parts.first;
          }
        } catch (_) {}
      }
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Charger uniquement le dashboard
  Future<void> loadDashboard() async {
    _setLoading(true);
    try {
      _dashboard = await ApiConfig().studentService.getDashboard();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Charger les semestres
  Future<void> loadSemestres() async {
    _setLoading(true);
    try {
      _semestres = await ApiConfig().studentService.getSemestres();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Charger les notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    try {
      _notifications = await ApiConfig().studentService.getNotifications();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String id) async {
    try {
      // L'API acceptant désormais un String, on lui passe directement l'id
      await ApiConfig().studentService.markNotificationAsRead(id);

      // Mettre à jour localement la liste Flutter
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          channel: _notifications[index].channel,
          data: _notifications[index].data,
          reclamationId: _notifications[index].reclamationId,
          sentAt: _notifications[index].sentAt,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead() async {
    try {
      await ApiConfig().studentService.markAllNotificationsAsRead();
      // Mettre à jour localement
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        isRead: true,
        readAt: DateTime.now().toIso8601String(),
        channel: n.channel,
        data: n.data,
        reclamationId: n.reclamationId,
        sentAt: n.sentAt,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String id) async {
    try {
      // L'API acceptant désormais un String, on lui passe directement l'id
      await ApiConfig().studentService.deleteNotification(id);

      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Rafraîchir les compteurs de notifications
  Future<void> refreshNotificationCounts() async {
    try {
      _notificationCounts = await ApiConfig().studentService.getNotificationCounts();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
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
}