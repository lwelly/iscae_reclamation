import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/notification_model.dart';
import 'notification_ui_helpers.dart';
import 'reclamation_detail_screen.dart';

/// Affiche le contenu complet d'une notification.
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  int? get _reclamationId {
    final fromField = notification.reclamationId;
    if (fromField != null) {
      final id = int.tryParse(fromField);
      if (id != null) return id;
    }
    final data = notification.data;
    if (data != null) {
      for (final key in ['reclamation_id', 'id']) {
        final v = data[key];
        if (v != null) {
          final id = int.tryParse(v.toString());
          if (id != null && id > 0) return id;
        }
      }
    }
    return null;
  }

  bool get _hasReclamationLink => _reclamationId != null && _reclamationId! > 0;

  String get _bodyText {
    if (notification.body.trim().isNotEmpty) return notification.body.trim();
    final data = notification.data;
    if (data == null) return 'Aucun détail supplémentaire.';
    for (final key in ['message', 'body', 'content', 'description', 'text']) {
      final v = data[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return 'Aucun détail supplémentaire.';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final type = notification.type;
    final typeColor = NotificationUi.color(type);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.appBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: NotificationUi.bg(type),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(NotificationUi.icon(type), color: typeColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Chip(
                                label: Text(
                                  NotificationUi.typeLabel(type),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: typeColor.withValues(alpha: context.isDarkMode ? 0.2 : 0.12),
                                labelStyle: TextStyle(color: typeColor),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                side: BorderSide.none,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.appOnSurface,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: context.appMuted),
                        const SizedBox(width: 6),
                        Text(
                          _formatFullDate(notification.createdAt ?? notification.sentAt),
                          style: TextStyle(fontSize: 13, color: context.appMuted),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Non lue',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Message',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: context.appMuted,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.appBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  _bodyText,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: context.appOnSurface,
                  ),
                ),
              ),
            ),
            if (_extraDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Détails',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: context.appMuted,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.appBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: _extraDetails
                        .map(
                          (e) => ListTile(
                            dense: true,
                            title: Text(e.$1, style: TextStyle(fontSize: 12, color: context.appMuted)),
                            subtitle: Text(e.$2, style: TextStyle(fontSize: 14, color: context.appOnSurface)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            if (_hasReclamationLink) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => ReclamationDetailScreen(id: _reclamationId!),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text('Voir la réclamation'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<(String, String)> get _extraDetails {
    final data = notification.data;
    if (data == null || data.isEmpty) return [];
    const skip = {'title', 'message', 'body', 'content', 'description', 'text', 'reclamation_id', 'id', 'link'};
    final out = <(String, String)>[];
    for (final entry in data.entries) {
      if (skip.contains(entry.key)) continue;
      final v = entry.value;
      if (v == null || v is Map || v is List) continue;
      final text = v.toString().trim();
      if (text.isEmpty) continue;
      out.add((_labelForKey(entry.key), text));
    }
    return out;
  }

  String _labelForKey(String key) {
    const labels = {
      'status': 'Statut',
      'matricule': 'Matricule',
      'reference': 'Référence',
      'document_id': 'Document',
      'meeting_at': 'Rendez-vous',
      'old_status': 'Ancien statut',
      'new_status': 'Nouveau statut',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Date inconnue';
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '${d.day} ${months[d.month - 1]} ${d.year} à $h:$m';
    } catch (_) {
      return dateStr;
    }
  }
}
