import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../core/config/api_config.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, int>? _counts;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  Map<String, int>? get counts => _counts;
  int get unreadCount => _counts?['unread'] ?? 0;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = null;
  }

  // Charger toutes les notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      _notifications = await ApiConfig().studentService.getNotifications();
      await loadCounts();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Charger les comptes de notifications
  Future<void> loadCounts() async {
    try {
      _counts = await ApiConfig().studentService.getNotificationCounts();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String id) async {
    try {
      await ApiConfig().studentService.markNotificationAsRead(id);
      
      // Mettre à jour localement
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
        await loadCounts();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
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
      
      await loadCounts();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String id) async {
    try {
      await ApiConfig().studentService.deleteNotification(id);
      
      // Supprimer localement
      _notifications.removeWhere((n) => n.id == id);
      await loadCounts();
    } catch (e) {
      _setError(e.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
