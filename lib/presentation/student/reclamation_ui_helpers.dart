import 'package:flutter/material.dart';

/// Libellés et couleurs alignés sur l'app Vue étudiant.
class ReclamationUi {
  ReclamationUi._();

  static const pendingStatuses = ['submitted', 'received', 'in_review', 'escalated'];
  static const resolvedStatuses = ['resolved', 'closed'];

  static const statusLabels = {
    'submitted': 'Soumise',
    'received': 'Reçue',
    'in_review': 'En cours',
    'escalated': 'Escaladée',
    'resolved': 'Résolue',
    'rejected': 'Rejetée',
    'closed': 'Fermée',
    'cancelled': 'Annulée',
  };

  static const statusColors = {
    'submitted': Color(0xFF2563EB),
    'received': Color(0xFF059669),
    'in_review': Color(0xFFD97706),
    'escalated': Color(0xFFEA580C),
    'resolved': Color(0xFF16A34A),
    'rejected': Color(0xFFDC2626),
    'closed': Color(0xFF6B7280),
    'cancelled': Color(0xFF6B7280),
  };

  static const statusBgColors = {
    'submitted': Color(0x1F2563EB),
    'received': Color(0x1F059669),
    'in_review': Color(0x1FD97706),
    'escalated': Color(0x1FEA580C),
    'resolved': Color(0x1F16A34A),
    'rejected': Color(0x1FDC2626),
    'closed': Color(0x1F6B7280),
    'cancelled': Color(0x1F6B7280),
  };

  static const statusIcons = {
    'submitted': Icons.send_rounded,
    'received': Icons.inbox_rounded,
    'in_review': Icons.manage_search_rounded,
    'escalated': Icons.arrow_upward_rounded,
    'resolved': Icons.check_circle_rounded,
    'rejected': Icons.cancel_rounded,
    'closed': Icons.lock_rounded,
    'cancelled': Icons.block_rounded,
  };

  static const statusDescriptions = {
    'submitted': 'Votre réclamation a été soumise et est en attente de réception.',
    'received': "Votre réclamation a été reçue par l'administration.",
    'in_review': "Votre réclamation est en cours d'examen.",
    'escalated': 'Votre réclamation a été transmise à un responsable supérieur.',
    'resolved': 'Votre réclamation a été traitée avec succès.',
    'rejected': "Votre réclamation a été rejetée par l'administration.",
    'closed': 'Cette réclamation est fermée.',
    'cancelled': 'Cette réclamation a été annulée.',
  };

  static const typeLabels = {
    'cc': 'Devoir',
    'controle': 'Devoir',
    'examen': 'Examen',
    'rattrapage': 'Rattrapage',
  };

  static const typeColors = {
    'cc': Color(0xFF2563EB),
    'controle': Color(0xFF2563EB),
    'examen': Color(0xFFD97706),
    'rattrapage': Color(0xFF7C3AED),
  };

  static const typeBgColors = {
    'cc': Color(0x1F2563EB),
    'controle': Color(0x1F2563EB),
    'examen': Color(0x1FD97706),
    'rattrapage': Color(0x1F7C3AED),
  };

  static const typeIcons = {
    'cc': Icons.edit_note,
    'controle': Icons.edit_note,
    'examen': Icons.description_outlined,
    'rattrapage': Icons.refresh,
  };

  static String statusLabel(String? s) => statusLabels[s] ?? s ?? '—';
  static Color statusColor(String? s) => statusColors[s] ?? const Color(0xFF64748B);
  static Color statusBg(String? s) => statusBgColors[s] ?? const Color(0x1464748B);
  static IconData statusIcon(String? s) => statusIcons[s] ?? Icons.help_outline;
  static String statusDesc(String? s) => statusDescriptions[s] ?? '';

  static String typeLabel(String? t) => typeLabels[t] ?? t ?? '—';
  static Color typeColor(String? t) => typeColors[t] ?? Colors.grey;
  static Color typeBg(String? t) => typeBgColors[t] ?? const Color(0x1464748B);
  static IconData typeIcon(String? t) => typeIcons[t] ?? Icons.help_outline;

  static String formatDateShort(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d).toLocal();
      const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
      return '${dt.day.toString().padLeft(2, '0')} ${mois[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  static String formatTime(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  static String formatDateLong(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d).toLocal();
      const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
      return '${dt.day} ${mois[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  static String formatDateTime(String? d) {
    if (d == null || d.isEmpty) return '—';
    final date = formatDateShort(d);
    final time = formatTime(d);
    return time.isEmpty ? date : '$date à $time';
  }

  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / 1048576).toStringAsFixed(1)} Mo';
  }

  static IconData attachmentIcon(String? mime) {
    if (mime == null) return Icons.insert_drive_file_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('image')) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static Color attachmentIconColor(String? mime) {
    if (mime == null) return Colors.grey;
    if (mime.contains('pdf')) return Colors.red;
    if (mime.contains('image')) return Colors.blue;
    return Colors.grey;
  }

  static String processingDelay(String? createdAt, String? resolvedAt) {
    if (createdAt == null || createdAt.isEmpty) return '—';
    try {
      final start = DateTime.parse(createdAt);
      final end = resolvedAt != null && resolvedAt.isNotEmpty
          ? DateTime.parse(resolvedAt)
          : DateTime.now();
      final days = end.difference(start).inDays;
      if (days == 0) return "Moins d'un jour";
      return '$days jour${days > 1 ? 's' : ''}';
    } catch (_) {
      return '—';
    }
  }
}
