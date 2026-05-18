import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/notification_model.dart';
import 'notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données via le Provider
    Future.microtask(() => context.read<NotificationController>().loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
        actions: [
          if (controller.unreadCount > 0)
            TextButton.icon(
              onPressed: () => _markAllAsRead(controller),
              icon: const Icon(Icons.mark_email_read, size: 20),
              label: const Text('Tout marquer comme lu'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.hasError) {
            return Center(
              key: const Key('notification_error_center'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${controller.errorMessage}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadNotifications(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          return _buildNotificationsContent(controller);
        },
      ),
    );
  }

  Widget _buildNotificationsContent(NotificationController controller) {
    final notifications = controller.notifications;

    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune notification', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadNotifications(),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification, controller);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead ? Colors.grey.withOpacity(0.1) : Colors.blue.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: notification.isRead ? Colors.grey.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          child: Icon(
            _getIconForType(notification.type),
            color: notification.isRead ? Colors.grey : Colors.blue,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: notification.isRead ? Colors.grey[700] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              IconButton(
                icon: const Icon(Icons.mark_email_read_outlined, size: 20),
                onPressed: () => controller.markAsRead(notification.id),
                tooltip: 'Marquer comme lu',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _showDeleteDialog(notification, controller),
              tooltip: 'Supprimer',
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            controller.markAsRead(notification.id);
          }
          // TODO: Naviguer vers la réclamation si reclamationId existe
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'reclamation':
        return Icons.assignment;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'Il y a ${difference.inHours} h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} j';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  void _markAllAsRead(NotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer tout comme lu'),
        content: const Text('Voulez-vous marquer toutes les notifications comme lues ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.markAllAsRead();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(NotificationModel notification, NotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text('Voulez-vous supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteNotification(notification.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
