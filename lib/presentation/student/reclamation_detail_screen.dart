import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/reclamation_model.dart';
import 'reclamation_controller.dart';
import 'reclamation_ui_helpers.dart';

class ReclamationDetailScreen extends StatefulWidget {
  final int id;
  final bool embedded;
  final VoidCallback? onBack;

  const ReclamationDetailScreen({
    super.key,
    required this.id,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<ReclamationDetailScreen> createState() => _ReclamationDetailScreenState();
}

class _ReclamationDetailScreenState extends State<ReclamationDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReclamationController>().fetchDetails(widget.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_ProgressStep> _progressSteps(ReclamationModel rec) {
    const order = ['submitted', 'received', 'in_review', 'resolved'];
    final current = rec.status;
    final idx = current == 'rejected'
        ? order.indexOf('in_review')
        : order.indexOf(current).clamp(0, order.length - 1);
    final labels = ['Soumis', 'Reçu', 'En cours', current == 'rejected' ? 'Rejeté' : 'Résolu'];
    return List.generate(4, (i) {
      return _ProgressStep(
        label: labels[i],
        done: i < idx,
        active: i == idx,
        rejected: current == 'rejected' && i == idx,
      );
    });
  }

  void _handleBackPressed() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  static String _formatNote(num value) {
    final d = value.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    final s = d.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final body = Consumer<ReclamationController>(
      builder: (context, controller, _) {
        final rec = controller.selectedReclamation;
        final loading = controller.isLoadingDetail;
        final error = controller.errorMessage;

        if (loading) return const Center(child: CircularProgressIndicator());
        if (error != null && rec == null) return _ErrorState(message: error, onBack: _handleBackPressed);
        if (rec != null) return _buildContent(context, rec, primary, controller);
        return const SizedBox.shrink();
      },
    );

    if (widget.embedded) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBackPressed();
        },
        child: body,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: body,
      ),
    );
  }

  Widget _buildStatusBanner(ReclamationModel rec, Color statusColor, {required bool narrow}) {
    final dateWidget = (rec.resolvedAt != null || rec.updatedAt.isNotEmpty)
        ? Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 12, color: context.appMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            ReclamationUi.formatDateTime(rec.resolvedAt ?? rec.updatedAt),
            style: TextStyle(fontSize: 11, color: context.appMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )
        : null;

    final mainRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: narrow ? 40 : 48,
          height: narrow ? 40 : 48,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ReclamationUi.statusIcon(rec.status), color: Colors.white, size: narrow ? 20 : 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReclamationUi.statusLabel(rec.status),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: narrow ? 13 : 14),
              ),
              Text(
                ReclamationUi.statusDesc(rec.status),
                style: TextStyle(fontSize: 11, color: context.appMuted),
              ),
            ],
          ),
        ),
        if (!narrow && dateWidget != null) dateWidget,
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReclamationUi.statusBg(rec.status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainRow,
          if (narrow && dateWidget != null) ...[
            const SizedBox(height: 8),
            dateWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildModuleSemesterRow(ReclamationModel rec, {required bool stack}) {
    final module = _ModuleCard(
      icon: Icons.menu_book,
      iconGradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      code: rec.module.code,
      name: rec.module.name,
      stats: [
        ('Coefficient', rec.module.coefficient ?? '—'),
        ('Crédits', rec.module.credits ?? '—'),
      ],
    );
    final semestre = _ModuleCard(
      icon: Icons.calendar_month,
      iconGradient: const [Color(0xFF0891B2), Color(0xFF0EA5E9)],
      code: rec.semestre.code,
      name: rec.semestre.label,
      codeColor: const Color(0xFF0891B2),
      stats: [

      ],
    );
    if (stack) {
      return Column(
        children: [
          module,
          const SizedBox(height: 12),
          semestre,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: module),
        const SizedBox(width: 12),
        Expanded(child: semestre),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ReclamationModel rec, Color primary, ReclamationController controller) {
    final statusColor = ReclamationUi.statusColor(rec.status);
    final steps = _progressSteps(rec);
    final meeting = rec.meeting;
    final topInset = widget.embedded ? 0.0 : MediaQuery.paddingOf(context).top;
    final pad = MediaQuery.sizeOf(context).width >= 700 ? 24.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, topInset + (widget.embedded ? 8 : 20), pad, 12),
          child: _buildPageHeader(rec, statusColor),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Suivi'),
              Tab(text: 'Détails'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSuiviTab(context, rec, statusColor, steps, meeting, pad),
              _buildDetailsTab(context, rec, meeting, pad),
              _buildHistoriqueTab(rec, pad),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(ReclamationModel rec, Color statusColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPressed,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Suivez l'état de votre réclamation",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appOnSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ReclamationUi.statusIcon(rec.status), color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          ReclamationUi.statusLabel(rec.status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.appSurfaceLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Text(
                      '#${rec.referenceNumber}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.appMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuiviTab(
    BuildContext context,
    ReclamationModel rec,
    Color statusColor,
    List<_ProgressStep> steps,
    Map<String, dynamic>? meeting,
    double pad,
  ) {
    final stackModules = MediaQuery.sizeOf(context).width < 700;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusBanner(rec, statusColor, narrow: stackModules),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Progression',
            icon: Icons.track_changes,
            child: _ProgressBar(steps: steps, compact: stackModules),
          ),
          const SizedBox(height: 16),
          _buildModuleSemesterRow(rec, stack: stackModules),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Informations rapides',
            icon: Icons.bolt,
            child: Column(
              children: [
                _QuickRow('Référence', rec.referenceNumber),
                _QuickRow('Type', ReclamationUi.typeLabel(rec.type), chip: ReclamationUi.typeColor(rec.type)),
                _QuickRow('Soumis le', ReclamationUi.formatDateLong(rec.createdAt)),
                if (rec.resolvedAt != null) _QuickRow('Résolu le', ReclamationUi.formatDateLong(rec.resolvedAt)),
                _QuickRow('Délai de traitement', ReclamationUi.processingDelay(rec.createdAt, rec.resolvedAt)),
                if (rec.academicYear.isNotEmpty) _QuickRow('Année univ.', rec.academicYear),
              ],
            ),
          ),
          if (rec.isEscalated) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Réclamation escaladée',
              icon: Icons.arrow_upward,
              iconColor: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rec.escalationReason != null)
                    Text(rec.escalationReason!, style: const TextStyle(height: 1.5, fontSize: 12)),
                  if (rec.escalatedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: context.appMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ReclamationUi.formatDateTime(rec.escalatedAt),
                            style: TextStyle(fontSize: 11, color: context.appMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (meeting != null && meeting['scheduled_at'] != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Réunion planifiée',
              icon: Icons.event,
              iconColor: Colors.blue,
              child: Column(
                children: [
                  _InfoRow('Date & Heure', ReclamationUi.formatDateTime(meeting['scheduled_at']?.toString())),
                  if (meeting['location'] != null) _InfoRow('Lieu', meeting['location'].toString()),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _handleBackPressed,
            icon: const Icon(Icons.list, size: 16),
            label: const Text('Voir toutes mes réclamations', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, ReclamationModel rec, Map<String, dynamic>? meeting, double pad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Détails de la réclamation',
            icon: Icons.info_outline,
            child: Column(
              children: [
                _InfoRow('Référence', rec.referenceNumber, mono: true),
                _InfoRow('Type', ReclamationUi.typeLabel(rec.type), chip: true, chipColor: ReclamationUi.typeColor(rec.type)),
                _InfoRow('Note actuelle', '${_formatNote(rec.noteActuelle)} / 20', note: true),
                _InfoRow(
                  'Note réclamée',
                  rec.noteReclamee != null ? '${_formatNote(rec.noteReclamee!)} / 20' : '—',
                  noteClaim: true,
                ),
                _InfoRow('Date de soumission', ReclamationUi.formatDateTime(rec.createdAt)),
                if (rec.resolvedAt != null)
                  _InfoRow('Date de résolution', ReclamationUi.formatDateTime(rec.resolvedAt)),
              ],
            ),
          ),
          if (rec.justification.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Justification',
              icon: Icons.description_outlined,
              child: Text(rec.justification, style: const TextStyle(fontSize: 13, height: 1.65)),
            ),
          ],
          if (rec.adminResponse != null && rec.adminResponse!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AdminResponseCard(
              response: rec.adminResponse!,
              rejected: rec.status == 'rejected',
              date: rec.respondedAt,
            ),
          ],
          if (meeting != null && meeting['scheduled_at'] != null && meeting['notes'] != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Notes de réunion',
              icon: Icons.notes,
              child: Text(meeting['notes'].toString(), style: const TextStyle(fontSize: 12, height: 1.5)),
            ),
          ],
          if (rec.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Pièces jointes (${rec.attachments.length})',
              icon: Icons.attach_file,
              child: Column(
                children: rec.attachments.map((a) => _AttachmentRow(attachment: a)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoriqueTab(ReclamationModel rec, double pad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      child: _SectionCard(
        title: 'Historique des statuts',
        icon: Icons.history,
        child: rec.history.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 40, color: context.appMuted),
                    const SizedBox(height: 12),
                    Text('Aucun historique disponible', style: TextStyle(fontSize: 13, color: context.appMuted)),
                  ],
                ),
              )
            : _HistoryTimeline(items: rec.history),
      ),
    );
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────

class _ProgressStep {
  final String label;
  final bool done;
  final bool active;
  final bool rejected;
  const _ProgressStep({required this.label, required this.done, required this.active, this.rejected = false});
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final List<_ProgressStep> steps;
  final bool compact;

  const _ProgressBar({required this.steps, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final circleSize = compact ? 24.0 : 28.0;
    final iconSize   = compact ? 12.0 : 14.0;
    final labelSize  = compact ? 8.0  : 10.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8, horizontal: compact ? 2 : 8),
      child: Row(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          Color circleColor = Colors.grey.shade200;
          Color borderColor = Colors.grey.shade400;
          Color? fillColor;
          Widget child;

          if (s.done) {
            fillColor = const Color(0xFF059669);
            borderColor = fillColor;
            child = Icon(Icons.check, color: Colors.white, size: iconSize);
          } else if (s.rejected) {
            fillColor = const Color(0xFFDC2626);
            borderColor = fillColor;
            child = Icon(Icons.close, color: Colors.white, size: iconSize);
          } else if (s.active) {
            fillColor = s.rejected ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
            borderColor = fillColor;
            child = Text(
              '${i + 1}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: compact ? 9 : 11),
            );
          } else {
            child = Text(
              '${i + 1}',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: compact ? 9 : 11),
            );
          }

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(child: Container(height: 2, color: s.done || s.active ? const Color(0xFF059669) : Colors.grey.shade300)),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: fillColor ?? circleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: s.active
                            ? [BoxShadow(color: (fillColor ?? Colors.blue).withOpacity(0.3), blurRadius: 0, spreadRadius: compact ? 2 : 3)]
                            : null,
                      ),
                      child: Center(child: child),
                    ),
                    if (i < steps.length - 1)
                      Expanded(child: Container(height: 2, color: s.done ? const Color(0xFF059669) : Colors.grey.shade300)),
                  ],
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: s.active ? FontWeight.w700 : FontWeight.w500,
                    color: s.rejected
                        ? const Color(0xFFDC2626)
                        : s.done
                        ? const Color(0xFF059669)
                        : s.active
                        ? const Color(0xFF2563EB)
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 17),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool chip;
  final Color? chipColor;
  final bool note;
  final bool noteClaim;

  const _InfoRow(
      this.label,
      this.value, {
        this.mono = false,
        this.chip = false,
        this.chipColor,
        this.note = false,
        this.noteClaim = false,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
          if (chip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (chipColor ?? Colors.grey).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: chipColor)),
            )
          else
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: note || noteClaim ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2) : null,
                  decoration: note || noteClaim
                      ? BoxDecoration(
                    color: noteClaim ? const Color(0x1FEA580C) : const Color(0x1F2563EB),
                    borderRadius: BorderRadius.circular(6),
                  )
                      : mono
                      ? BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      fontFamily: mono ? 'monospace' : null,
                      color: noteClaim ? const Color(0xFFC2410C) : note ? const Color(0xFF1D4ED8) : null,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String code;
  final String name;
  final List<(String, String)> stats;
  final Color? codeColor;

  const _ModuleCard({
    required this.icon,
    required this.iconGradient,
    required this.code,
    required this.name,
    required this.stats,
    this.codeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: iconGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: codeColor ?? const Color(0xFF6366F1),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: stats
                  .map((s) => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1, style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminResponseCard extends StatelessWidget {
  final String response;
  final bool rejected;
  final String? date;

  const _AdminResponseCard({required this.response, required this.rejected, this.date});

  @override
  Widget build(BuildContext context) {
    final color = rejected ? const Color(0xFFDC2626) : const Color(0xFF059669);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: color.withOpacity(0.08),
            child: Row(
              children: [
                Icon(rejected ? Icons.cancel : Icons.check_circle, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Réponse de l'administration",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (date != null)
                  Text(ReclamationUi.formatDateTime(date), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(response, style: const TextStyle(height: 1.7, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final ReclamationAttachment attachment;
  const _AttachmentRow({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            ReclamationUi.attachmentIcon(attachment.mimeType),
            color: ReclamationUi.attachmentIconColor(attachment.mimeType),
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSize != null)
                  Text(ReclamationUi.formatFileSize(attachment.fileSize), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          if (attachment.url != null)
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: attachment.url!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié dans le presse-papiers', style: TextStyle(fontSize: 12))),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final List<ReclamationHistory> items;

  const _HistoryTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (i) {
        final h = items[i];
        final isLast = i == items.length - 1;
        final statusColor = ReclamationUi.statusColor(h.newStatus);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: statusColor.withValues(alpha: 0.35), blurRadius: 4),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: context.appBorder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (h.oldStatus != null) ...[
                              _StatusMiniChip(status: h.oldStatus!),
                              Icon(Icons.arrow_forward, size: 12, color: context.appMuted),
                            ],
                            _StatusMiniChip(status: h.newStatus, filled: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: context.appMuted),
                            const SizedBox(width: 4),
                            Text(
                              ReclamationUi.formatDateTime(h.createdAt),
                              style: TextStyle(fontSize: 11, color: context.appMuted),
                            ),
                          ],
                        ),
                        if (h.comment != null && h.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(h.comment!, style: const TextStyle(fontSize: 12, height: 1.45)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: context.appMuted),
                            const SizedBox(width: 4),
                            Text(
                              h.changedByLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.appMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatusMiniChip extends StatelessWidget {
  final String status;
  final bool filled;
  const _StatusMiniChip({required this.status, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final color = ReclamationUi.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ReclamationUi.statusLabel(status),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: filled ? Colors.white : color),
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? chip;

  const _QuickRow(this.label, this.value, {this.chip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
          if (chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: chip!.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: chip)),
            )
          else
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorState({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Retour', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}