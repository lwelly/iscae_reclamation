import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/notification_model.dart';
import 'notification_controller.dart';
import 'notification_ui_helpers.dart';
import 'reclamation_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final void Function({int? reclamationId})? onOpenReclamations;

  const NotificationScreen({super.key, this.onOpenReclamations});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _perPage = 15;
  static const _tabs = [
    ('all', 'Toutes'),
    ('unread', 'Non lues'),
    ('reclamation', 'Réclamations'),
  ];

  String _activeTab = 'all';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => context.read<NotificationController>().loadNotifications(),
    );
  }

  void _onTabChanged(String tab) {
    setState(() {
      _activeTab = tab;
      _page = 1;
    });
  }

  List<NotificationModel> _paginated(NotificationController c) {
    final list = c.filtered(_activeTab);
    final start = (_page - 1) * _perPage;
    if (start >= list.length) return [];
    return list.sublist(start, (start + _perPage).clamp(0, list.length));
  }

  int _totalPages(NotificationController c) {
    final len = c.filtered(_activeTab).length;
    return len == 0 ? 0 : (len / _perPage).ceil();
  }

  List<({String date, List<NotificationModel> items})> _grouped(
      List<NotificationModel> list,
      ) {
    final map = <String, List<NotificationModel>>{};
    for (final n in list) {
      map.putIfAbsent(NotificationUi.dateLabel(n.createdAt), () => []).add(n);
    }
    return map.entries.map((e) => (date: e.key, items: e.value)).toList();
  }

  int? _reclamationIdFrom(NotificationModel notif) {
    final fromField = notif.reclamationId;
    if (fromField != null) {
      final id = int.tryParse(fromField);
      if (id != null && id > 0) return id;
    }
    final data = notif.data;
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

  Future<void> _handleClick(
      NotificationModel notif,
      NotificationController controller,
      ) async {
    if (!notif.isRead) await controller.markAsRead(notif.id);
    if (!mounted) return;

    final reclamationId = _reclamationIdFrom(notif);

    if (widget.onOpenReclamations != null) {
      widget.onOpenReclamations!(reclamationId: reclamationId);
      return;
    }

    await Navigator.of(context, rootNavigator: true).pushNamed('/reclamations');
    if (!mounted || reclamationId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReclamationDetailScreen(id: reclamationId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final primary = Theme.of(context).colorScheme.primary;
    final filtered = controller.filtered(_activeTab);
    final paginated = _paginated(controller);
    final groups = _grouped(paginated);
    final totalPages = _totalPages(controller);

    return RefreshIndicator(
      onRefresh: () => controller.loadNotifications(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(controller, primary),
            const SizedBox(height: 20),
            _buildFilters(controller, primary),
            const SizedBox(height: 20),
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.hasError && controller.notifications.isEmpty)
              _buildError(controller)
            else if (filtered.isEmpty)
                _buildEmpty()
              else ...[
                  ...groups.expand(
                        (g) => [
                      _dateLabel(g.date),
                      ...g.items.map(
                            (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildNotifCard(n, controller, primary),
                        ),
                      ),
                    ],
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 24),
                    _buildPagination(totalPages),
                  ],
                ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationController controller, Color primary) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.appOnSurface,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (controller.unreadCount > 0)
              OutlinedButton.icon(
                onPressed: controller.markingAll ? null : () => controller.markAllAsRead(),
                icon: controller.markingAll
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                )
                    : Icon(Icons.done_all, size: 18, color: primary),
                label: Text('Tout marquer lu', style: TextStyle(color: primary, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            OutlinedButton.icon(
              onPressed: controller.notifications.isEmpty || controller.clearingAll
                  ? null
                  : () => _showClearAllDialog(controller),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
              label: const Text('Tout effacer', style: TextStyle(color: Colors.red, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(NotificationController controller, Color primary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tabs.map((tab) {
            final selected = _activeTab == tab.$1;
            final count = controller.tabCount(tab.$1);
            return FilterChip(
              selected: selected,
              backgroundColor: context.appSurfaceLow,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.$2, style: const TextStyle(fontSize: 13)),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: selected ? Colors.white : primary,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? primary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (_) => _onTabChanged(tab.$1),
              selectedColor: primary,
              side: BorderSide(color: selected ? primary : context.appBorder),
              labelStyle: TextStyle(
                color: selected ? Colors.white : context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError(NotificationController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage ?? 'Erreur de chargement',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => controller.loadNotifications(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final message = _activeTab == 'unread'
        ? 'Vous avez lu toutes vos notifications.'
        : 'Vous n\'avez pas encore reçu de notifications.';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: context.appMuted),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.appMuted)),
          ],
        ),
      ),
    );
  }

  Widget _dateLabel(String date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(
        date.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: context.appMuted,
        ),
      ),
    );
  }

  Widget _buildNotifCard(
      NotificationModel notif,
      NotificationController controller,
      Color primary,
      ) {
    final type = notif.type ?? '';
    final typeColor = _notifColor(context, type);
    final unread = !notif.isRead;
    final border = context.appBorder;

    return Material(
      color: unread ? primary.withValues(alpha: 0.05) : context.appCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleClick(notif, controller),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: unread ? primary : border, width: unread ? 4 : 1),
              top: BorderSide(color: border),
              right: BorderSide(color: border),
              bottom: BorderSide(color: border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: context.isDarkMode ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_notifIcon(type), color: typeColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: context.appOnSurface,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 6),
                              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(
                            _notifTypeLabel(type),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: typeColor.withValues(alpha: context.isDarkMode ? 0.2 : 0.12),
                          labelStyle: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          side: BorderSide.none,
                        ),
                      ),
                      if (notif.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notif.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: context.appMuted),
                          const SizedBox(width: 4),
                          Text(
                            NotificationUi.fmtTime(notif.createdAt),
                            style: TextStyle(fontSize: 11, color: context.appMuted),
                          ),
                          const Spacer(),
                          if (unread)
                            TextButton(
                              onPressed: controller.isMarking(notif.id) ? null : () => controller.markAsRead(notif.id),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: controller.isMarking(notif.id)
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Text('Marquer lu', style: TextStyle(fontSize: 11)),
                            ),
                          IconButton(
                            icon: controller.isDeleting(notif.id)
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.delete_outline, size: 20),
                            color: Colors.red,
                            visualDensity: VisualDensity.compact,
                            onPressed: controller.isDeleting(notif.id) ? null : () => controller.deleteNotification(notif.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _page > 1 ? () => setState(() => _page--) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        ...List.generate(totalPages.clamp(0, 7), (i) {
          int pageNum;
          if (totalPages <= 7) {
            pageNum = i + 1;
          } else if (_page <= 4) {
            pageNum = i + 1;
          } else if (_page >= totalPages - 3) {
            pageNum = totalPages - 6 + i;
          } else {
            pageNum = _page - 3 + i;
          }
          final selected = pageNum == _page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _page = pageNum),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pageNum',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : context.appOnSurface,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: _page < totalPages ? () => setState(() => _page++) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _showClearAllDialog(NotificationController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_sweep_outlined, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Effacer toutes les notifications ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Cette action est irréversible.', style: TextStyle(fontSize: 13, color: context.appMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: controller.clearingAll
                ? null
                : () async {
              await controller.clearAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() => _page = 1);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: controller.clearingAll
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  IconData _notifIcon(String type) {
    if (type.contains('reclamation')) return Icons.description_outlined;
    if (type.contains('status')) return Icons.swap_horiz;
    if (type.contains('meeting')) return Icons.event_available_outlined;
    if (type.contains('escalat')) return Icons.arrow_circle_up_outlined;
    if (type.contains('resolved')) return Icons.check_circle_outline;
    if (type.contains('rejected')) return Icons.cancel_outlined;
    if (type.contains('document')) return Icons.attach_file;
    if (type.contains('note')) return Icons.sticky_note_2_outlined;
    if (type.contains('system') || type.contains('general')) return Icons.info_outline;
    return Icons.notifications_outlined;
  }

  Color _notifColor(BuildContext context, String type) {
    if (type.contains('resolved')) return Colors.green;
    if (type.contains('rejected')) return Colors.red;
    if (type.contains('escalat')) return Colors.deepOrange;
    if (type.contains('meeting')) return Colors.purple;
    if (type.contains('reclamation')) return Theme.of(context).colorScheme.primary;
    if (type.contains('document')) return Colors.teal;
    if (type.contains('note')) return Colors.amber;
    if (type.contains('system') || type.contains('general')) return Colors.blueGrey;
    return Colors.blueGrey;
  }

  String _notifTypeLabel(String type) {
    if (type.contains('reclamation')) return 'Réclamation';
    if (type.contains('meeting')) return 'RDV';
    if (type.contains('document')) return 'Document';
    if (type.contains('system')) return 'Système';
    if (type.contains('resolved')) return 'Résolu';
    if (type.contains('rejected')) return 'Refusé';
    if (type.contains('escalat')) return 'Escalade';
    if (type.contains('note')) return 'Note';
    return 'Info';
  }
}