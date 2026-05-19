import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/reclamation_model.dart';
import 'reclamation_controller.dart';
import 'reclamation_ui_helpers.dart';

class ReclamationDetailScreen extends StatefulWidget {
  final int id;

  const ReclamationDetailScreen({super.key, required this.id});

  @override
  State<ReclamationDetailScreen> createState() => _ReclamationDetailScreenState();
}

class _ReclamationDetailScreenState extends State<ReclamationDetailScreen> {
  final _cancelReasonController = TextEditingController();
  bool _confirmCancelDialog = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReclamationController>().fetchDetails(widget.id);
    });
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    super.dispose();
  }

  bool _canCancel(ReclamationModel? rec) =>
      rec != null && ['submitted', 'received'].contains(rec.status);

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

  Future<void> _cancelReclamation(ReclamationModel rec) async {
    setState(() => _cancelling = true);
    final controller = context.read<ReclamationController>();
    final success = await controller.cancelReclamation(int.parse(rec.id));
    if (!mounted) return;
    setState(() {
      _cancelling = false;
      _confirmCancelDialog = false;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réclamation annulée avec succès.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? "Erreur lors de l'annulation.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<ReclamationController>(
        builder: (context, controller, _) {
          final rec = controller.selectedReclamation;
          final loading = controller.isLoadingDetail;
          final error = controller.errorMessage;

          return Stack(
            children: [
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (error != null && rec == null)
                _ErrorState(message: error, onBack: () => Navigator.pop(context))
              else if (rec != null)
                _buildContent(context, rec, primary, controller),
              if (_confirmCancelDialog && rec != null)
                _CancelDialog(
                  reference: rec.referenceNumber,
                  reasonController: _cancelReasonController,
                  cancelling: _cancelling,
                  onClose: () => setState(() => _confirmCancelDialog = false),
                  onConfirm: () => _cancelReclamation(rec),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(ReclamationModel rec, Color statusColor, {required bool narrow}) {
    final dateWidget = (rec.resolvedAt != null || rec.updatedAt.isNotEmpty)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  ReclamationUi.formatDateTime(rec.resolvedAt ?? rec.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          width: narrow ? 44 : 52,
          height: narrow ? 44 : 52,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ReclamationUi.statusIcon(rec.status), color: Colors.white, size: narrow ? 22 : 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReclamationUi.statusLabel(rec.status),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: narrow ? 15 : 16),
              ),
              Text(
                ReclamationUi.statusDesc(rec.status),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (!narrow && dateWidget != null) dateWidget,
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 10),
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
        ('Année universitaire', rec.semestre.academicYear ?? rec.academicYear),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final pad = wide ? 24.0 : 16.0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Suivez l'état de votre réclamation",
                                style: TextStyle(
                                  fontSize: wide ? 22 : 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(ReclamationUi.statusIcon(rec.status), color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      ReclamationUi.statusLabel(rec.status),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${rec.referenceNumber}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (wide)
                      _buildWideLayout(context, rec, primary, controller, statusColor, steps, meeting)
                    else
                      _buildNarrowLayout(context, rec, primary, controller, statusColor, steps, meeting),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    ReclamationModel rec,
    Color primary,
    ReclamationController controller,
    Color statusColor,
    List<_ProgressStep> steps,
    Map<String, dynamic>? meeting,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._buildMainSections(rec, statusColor, steps, meeting, stackModules: true),
        const SizedBox(height: 16),
        ..._buildSidebarSections(rec, controller),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    ReclamationModel rec,
    Color primary,
    ReclamationController controller,
    Color statusColor,
    List<_ProgressStep> steps,
    Map<String, dynamic>? meeting,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(children: _buildMainSections(rec, statusColor, steps, meeting, stackModules: false)),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 320,
          child: Column(children: _buildSidebarSections(rec, controller)),
        ),
      ],
    );
  }

  List<Widget> _buildMainSections(
    ReclamationModel rec,
    Color statusColor,
    List<_ProgressStep> steps,
    Map<String, dynamic>? meeting, {
    required bool stackModules,
  }) {
    return [
      _buildStatusBanner(rec, statusColor, narrow: stackModules),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Progression',
        icon: Icons.track_changes,
        child: _ProgressBar(steps: steps, compact: stackModules),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Détails de la réclamation',
        icon: Icons.info_outline,
        child: Column(
          children: [
            _InfoRow('Référence', rec.referenceNumber, mono: true),
            _InfoRow('Type', ReclamationUi.typeLabel(rec.type), chip: true, chipColor: ReclamationUi.typeColor(rec.type)),
            _InfoRow('Note actuelle', '${rec.noteActuelle} / 20', note: true),
            _InfoRow(
              'Note réclamée',
              rec.noteReclamee != null ? '${rec.noteReclamee} / 20' : '—',
              noteClaim: true,
            ),
            _InfoRow('Date de soumission', ReclamationUi.formatDateTime(rec.createdAt)),
            if (rec.resolvedAt != null)
              _InfoRow('Date de résolution', ReclamationUi.formatDateTime(rec.resolvedAt)),
            if (rec.justification.isNotEmpty) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Justification', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ),
              const SizedBox(height: 6),
              Text(rec.justification, style: const TextStyle(fontSize: 14, height: 1.6)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildModuleSemesterRow(rec, stack: stackModules),
      const SizedBox(height: 16),
      if (rec.adminResponse != null && rec.adminResponse!.isNotEmpty)
        _AdminResponseCard(
          response: rec.adminResponse!,
          rejected: rec.status == 'rejected',
          date: rec.respondedAt,
        ),
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
              if (meeting['notes'] != null) ...[
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Notes', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ),
                const SizedBox(height: 4),
                Text(meeting['notes'].toString()),
              ],
            ],
          ),
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
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Historique des statuts',
        icon: Icons.history,
        child: rec.history.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Aucun historique disponible', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
            : Column(children: rec.history.map((h) => _HistoryItem(history: h)).toList()),
      ),
    ];
  }

  List<Widget> _buildSidebarSections(ReclamationModel rec, ReclamationController controller) {
    return [
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
                Text(rec.escalationReason!, style: const TextStyle(height: 1.5)),
              if (rec.escalatedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ReclamationUi.formatDateTime(rec.escalatedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (_canCancel(rec))
        OutlinedButton.icon(
          onPressed: () => setState(() => _confirmCancelDialog = true),
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: const Text('Annuler la réclamation', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      if (_canCancel(rec)) const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.list),
        label: const Text('Voir toutes mes réclamations'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
      ),
    ];
  }
}

class _ProgressStep {
  final String label;
  final bool done;
  final bool active;
  final bool rejected;
  const _ProgressStep({required this.label, required this.done, required this.active, this.rejected = false});
}

class _ProgressBar extends StatelessWidget {
  final List<_ProgressStep> steps;
  final bool compact;

  const _ProgressBar({required this.steps, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final circleSize = compact ? 26.0 : 32.0;
    final iconSize = compact ? 13.0 : 16.0;
    final labelSize = compact ? 9.0 : 11.0;

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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: compact ? 10 : 12),
            );
          } else {
            child = Text(
              '${i + 1}',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: compact ? 10 : 12),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          if (chip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (chipColor ?? Colors.grey).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: chipColor)),
            )
          else
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: note || noteClaim ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : null,
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
                      fontSize: 13,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: iconGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: codeColor ?? const Color(0xFF6366F1),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: stats
                  .map((s) => Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            padding: const EdgeInsets.all(14),
            color: color.withOpacity(0.08),
            child: Row(
              children: [
                Icon(rejected ? Icons.cancel : Icons.check_circle, color: color, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text("Réponse de l'administration", style: TextStyle(fontWeight: FontWeight.w600))),
                if (date != null)
                  Text(ReclamationUi.formatDateTime(date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(response, style: const TextStyle(height: 1.7, fontSize: 14)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            ReclamationUi.attachmentIcon(attachment.mimeType),
            color: ReclamationUi.attachmentIconColor(attachment.mimeType),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSize != null)
                  Text(ReclamationUi.formatFileSize(attachment.fileSize), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (attachment.url != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: attachment.url!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié dans le presse-papiers')),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ReclamationHistory history;
  const _HistoryItem({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (history.oldStatus != null) ...[
                _StatusMiniChip(status: history.oldStatus!),
                const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
              ],
              _StatusMiniChip(status: history.newStatus, filled: true),
              Text(ReclamationUi.formatDateTime(history.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          if (history.comment != null && history.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(history.comment!, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(history.changedByLabel, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ReclamationUi.statusLabel(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: filled ? Colors.white : color),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          if (chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: chip!.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: chip)),
            )
          else
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}

class _CancelDialog extends StatelessWidget {
  final String reference;
  final TextEditingController reasonController;
  final bool cancelling;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  const _CancelDialog({
    required this.reference,
    required this.reasonController,
    required this.cancelling,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Annuler la réclamation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Êtes-vous sûr de vouloir annuler la réclamation $reference ?'),
                const SizedBox(height: 4),
                const Text('Cette action est irréversible.', style: TextStyle(color: Colors.red, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: "Motif d'annulation (optionnel)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: cancelling ? null : onClose, child: const Text('Conserver')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: cancelling ? null : onConfirm,
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: cancelling
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Confirmer l'annulation"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
