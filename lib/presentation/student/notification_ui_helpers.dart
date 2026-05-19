import 'package:flutter/material.dart';

class NotificationUi {
  static IconData icon(String? type) {
    final t = type ?? '';
    if (t.contains('reclamation')) return Icons.description_outlined;
    if (t.contains('status')) return Icons.swap_horiz;
    if (t.contains('meeting')) return Icons.event_available_outlined;
    if (t.contains('escalat')) return Icons.arrow_circle_up_outlined;
    if (t.contains('resolved')) return Icons.check_circle_outline;
    if (t.contains('rejected')) return Icons.cancel_outlined;
    if (t.contains('document')) return Icons.attach_file;
    return Icons.notifications_outlined;
  }

  static Color color(String? type) {
    final t = type ?? '';
    if (t.contains('resolved')) return Colors.green;
    if (t.contains('rejected')) return Colors.red;
    if (t.contains('escalat')) return Colors.deepOrange;
    if (t.contains('meeting')) return Colors.purple;
    if (t.contains('reclamation')) return Colors.blue;
    if (t.contains('document')) return Colors.teal;
    return Colors.blueGrey;
  }

  static Color bg(String? type) => color(type).withValues(alpha: 0.12);

  static String typeLabel(String? type) {
    final t = type ?? '';
    if (t.contains('reclamation')) return 'Réclamation';
    if (t.contains('meeting')) return 'RDV';
    if (t.contains('document')) return 'Document';
    if (t.contains('system')) return 'Système';
    return 'Info';
  }

  static String dateLabel(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Date inconnue';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final dDate = DateTime(d.year, d.month, d.day);
      final nowDate = DateTime(now.year, now.month, now.day);
      final diff = nowDate.difference(dDate).inDays;
      if (diff == 0) return "Aujourd'hui";
      if (diff == 1) return 'Hier';
      if (diff < 7) return 'Il y a $diff jours';
      const months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  static String fmtTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(d).inMinutes;
      if (diff < 1) return "À l'instant";
      if (diff < 60) return 'Il y a $diff min';
      if (diff < 1440) {
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
      const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }
}
