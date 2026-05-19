import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../data/models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _markingAll = false;
  bool _clearingAll = false;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, int>? _counts;
  final Set<String> _markingIds = {};
  final Set<String> _deletingIds = {};

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get markingAll => _markingAll;
  bool get clearingAll => _clearingAll;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  Map<String, int>? get counts => _counts;

  int get unreadCount =>
      _counts?['unread'] ?? _notifications.where((n) => !n.isRead).length;

  bool isMarking(String id) => _markingIds.contains(id);
  bool isDeleting(String id) => _deletingIds.contains(id);

  List<NotificationModel> filtered(String tab) {
    switch (tab) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'reclamation':
        return _notifications.where((n) => n.type?.contains('reclamation') == true).toList();
      default:
        return _notifications;
    }
  }

  int tabCount(String tab) {
    switch (tab) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).length;
      case 'reclamation':
        return _notifications.where((n) => n.type?.contains('reclamation') == true).length;
      default:
        return _notifications.length;
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await ApiConfig().studentService.getNotifications();
      await loadCounts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadCounts() async {
    try {
      _counts = await ApiConfig().studentService.getNotificationCounts();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> markAsRead(String id) async {
    _markingIds.add(id);
    notifyListeners();
    try {
      await ApiConfig().studentService.markNotificationAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
        );
      }
      await loadCounts();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      return false;
    } finally {
      _markingIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> markAllAsRead() async {
    _markingAll = true;
    notifyListeners();
    try {
      await ApiConfig().studentService.markAllNotificationsAsRead();
      final now = DateTime.now().toIso8601String();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: n.readAt ?? now))
          .toList();
      await loadCounts();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      return false;
    } finally {
      _markingAll = false;
      notifyListeners();
    }
  }

  Future<bool> deleteNotification(String id) async {
    _deletingIds.add(id);
    notifyListeners();
    try {
      await ApiConfig().studentService.deleteNotification(id);
      _notifications.removeWhere((n) => n.id == id);
      await loadCounts();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      return false;
    } finally {
      _deletingIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> clearAll() async {
    _clearingAll = true;
    notifyListeners();
    try {
      final ids = _notifications.map((n) => n.id).toList();
      await Future.wait(ids.map((id) => ApiConfig().studentService.deleteNotification(id)));
      _notifications = [];
      await loadCounts();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      return false;
    } finally {
      _clearingAll = false;
      notifyListeners();
    }
  }
}
