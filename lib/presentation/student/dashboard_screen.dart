import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/reclamation_model.dart';
import 'create_reclamation_screen.dart';
import 'dashboard_controller.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_screen.dart';

/// Couleurs graphiques alignées sur DashboardView.vue
class _DashColors {
  static const submitted = Color(0xFF60A5FA);
  static const inReview = Color(0xFFFBBF24);
  static const escalated = Color(0xFFFB923C);
  static const resolved = Color(0xFF34D399);
  static const rejected = Color(0xFFF87171);
  static const closed = Color(0xFF6B7280);
  static const chartBlue = Color(0xFF3B82F6);

  static Color statusColor(String status) => switch (status) {
    'submitted' => submitted,
    'in_review' => inReview,
    'escalated' => escalated,
    'resolved' => resolved,
    'rejected' => rejected,
    'closed' => closed,
    _ => closed,
  };

  static String statusLabel(String status) => switch (status) {
    'submitted' => 'Soumise',
    'in_review' => 'En cours',
    'escalated' => 'Escaladée',
    'resolved' => 'Résolue',
    'rejected' => 'Rejetée',
    'closed' => 'Fermée',
    _ => status,
  };
}

class StudentDashboard extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onNewReclamation;
  final VoidCallback? onViewAllReclamations;

  const StudentDashboard({
    super.key,
    this.embedded = false,
    this.onNewReclamation,
    this.onViewAllReclamations,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  _ChartType _chartType = _ChartType.bar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadAllData();
    });
  }

  String get _todayLabel {
    final now = DateTime.now();
    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]} ${now.year}';
  }

  ({List<String> labels, List<double> data}) _buildMonthlyData(List<ReclamationModel> items) {
    final map = <String, int>{};
    final now = DateTime.now();
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      map[key] = 0;
    }
    for (final r in items) {
      if (r.createdAt.isEmpty) continue;
      try {
        final d = DateTime.parse(r.createdAt);
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        if (map.containsKey(key)) map[key] = map[key]! + 1;
      } catch (_) {}
    }
    final sorted = map.keys.toList()..sort();
    const mois = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    final labels = sorted.map((k) {
      final parts = k.split('-');
      final m = int.parse(parts[1]);
      final label = mois[m - 1];
      return label[0].toUpperCase() + label.substring(1);
    }).toList();
    return (labels: labels, data: sorted.map((k) => map[k]!.toDouble()).toList());
  }

  void _openNewReclamation() {
    if (widget.onNewReclamation != null) {
      widget.onNewReclamation!();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReclamationScreen()));
    }
  }

  void _openAllReclamations() {
    if (widget.onViewAllReclamations != null) {
      widget.onViewAllReclamations!();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReclamationScreen()));
    }
  }

  void _openDetail(ReclamationModel r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReclamationDetailScreen(id: int.parse(r.id))),
    );
  }

  String _formatDateShort(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d).toLocal();
      const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
      return '${dt.day.toString().padLeft(2, '0')} ${mois[dt.month - 1]}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.hasError && controller.reclamations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(controller.errorMessage ?? 'Erreur de chargement', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => controller.loadAllData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAllData(),
          child: ListView(
            padding: EdgeInsets.all(widget.embedded ? 12 : 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(controller),
                      const SizedBox(height: 20),
                      _buildKpis(controller),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 8, child: _buildMainChart(controller)),
                                const SizedBox(width: 16),
                                Expanded(flex: 4, child: _buildDoughnutCard(controller)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildMainChart(controller),
                              const SizedBox(height: 16),
                              _buildDoughnutCard(controller),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildRecentCard(controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: body,
    );
  }

  Widget _buildHeader(DashboardController controller) {
    final accent = Theme.of(context).colorScheme.primary;
    final narrow = MediaQuery.sizeOf(context).width < 480;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, ${controller.studentFirstName}',
          style: TextStyle(fontSize: narrow ? 15 : 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _todayLabel,
          style: TextStyle(fontSize: 11, color: context.dashTextMuted),
        ),
      ],
    );

    final newBtn = FilledButton.icon(
      onPressed: _openNewReclamation,
      icon: const Icon(Icons.add, size: 18),
      label: Text(narrow ? 'Nouvelle' : 'Nouvelle réclamation', style: const TextStyle(fontSize: 13)),
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 14, vertical: 10),
      ),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          newBtn,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        newBtn,
      ],
    );
  }

  Widget _buildKpis(DashboardController controller) {
    final loading = controller.isLoading;
    final kpis = [
      _KpiDef('Total', loading ? '—' : '${controller.totalCount}', Icons.assignment_outlined, const Color(0xFF60A5FA), const Color(0x263B82F6)),
      _KpiDef('En attente', loading ? '—' : '${controller.pendingCount}', Icons.schedule_outlined, const Color(0xFFFBBF24), const Color(0x26FBBF24)),
      _KpiDef('Résolues', loading ? '—' : '${controller.resolvedCount}', Icons.check_circle_outline, const Color(0xFF34D399), const Color(0x2634D399)),
      _KpiDef('Rejetées', loading ? '—' : '${controller.rejectedCount}', Icons.cancel_outlined, const Color(0xFFF87171), const Color(0x26F87171)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
        final aspectRatio = crossCount == 4 ? 1.8 : (constraints.maxWidth < 360 ? 1.15 : 1.35);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: kpis.map((k) => _KpiCard(kpi: k, compact: crossCount == 2)).toList(),
        );
      },
    );
  }

  Widget _buildMainChart(DashboardController controller) {
    final monthly = _buildMonthlyData(controller.reclamations);
    final maxY = monthly.data.isEmpty ? 4.0 : (monthly.data.reduce((a, b) => a > b ? a : b) + 1).clamp(4, 999).toDouble();

    return _ThemeCard(
      title: 'Évolution des réclamations',
      subtitle: 'Activité sur les 6 derniers mois',
      trailing: _ChartToggle(
        chartType: _chartType,
        onChanged: (t) => setState(() => _chartType = t),
      ),
      child: SizedBox(
        height: 320,
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: _chartType == _ChartType.bar
              ? BarChart(
            BarChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: context.dashGridLine, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: context.dashTextMuted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= monthly.labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(monthly.labels[i], style: TextStyle(fontSize: 10, color: context.dashTextMuted)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(monthly.data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: monthly.data[i],
                      color: _DashColors.chartBlue,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      width: 22,
                    ),
                  ],
                );
              }),
            ),
          )
              : LineChart(
            LineChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: context.dashGridLine, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: context.dashTextMuted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= monthly.labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(monthly.labels[i], style: TextStyle(fontSize: 10, color: context.dashTextMuted)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(monthly.data.length, (i) => FlSpot(i.toDouble(), monthly.data[i])),
                  isCurved: true,
                  color: _DashColors.chartBlue,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _DashColors.chartBlue.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoughnutCard(DashboardController controller) {
    final total = controller.totalCount;
    final legendDefs = [
      ('in_review', 'En attente', _DashColors.inReview),
      ('resolved', 'Résolues', _DashColors.resolved),
      ('rejected', 'Rejetées', _DashColors.rejected),
      ('submitted', 'Soumises', _DashColors.submitted),
      ('escalated', 'Escaladées', _DashColors.escalated),
    ];
    final counts = controller.statusCounts;
    final segments = legendDefs
        .map((s) {
      final count = counts[s.$1] ?? 0;
      return (key: s.$1, label: s.$2, color: s.$3, count: count, pct: total > 0 ? ((count / total) * 100).round() : 0);
    })
        .where((s) => s.count > 0)
        .toList();

    return _ThemeCard(
      title: 'Répartition',
      subtitle: 'Par statut',
      child: controller.isLoading
          ? const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))
          : Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (segments.isEmpty)
                    Center(child: Text('Aucune donnée', style: TextStyle(color: context.dashTextMuted)))
                  else
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 58,
                        sections: segments
                            .map(
                              (s) => PieChartSectionData(
                            value: s.count.toDouble(),
                            color: s.color,
                            radius: 28,
                            showTitle: false,
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                      Text('Total', style: TextStyle(fontSize: 11, color: context.dashTextMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...segments.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface))),
                  Text('${s.count}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 38,
                    child: Text('${s.pct}%', style: TextStyle(fontSize: 11, color: context.dashTextMuted), textAlign: TextAlign.right),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(DashboardController controller) {
    final recent = controller.recentReclamations;
    return _ThemeCard(
      title: 'Réclamations récentes',
      trailing: TextButton.icon(
        onPressed: _openAllReclamations,
        icon: const Icon(Icons.arrow_forward, size: 13),
        label: const Text('Voir tout'),
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 12),
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: controller.isLoading
          ? const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          : recent.isEmpty
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text('Aucune réclamation pour le moment', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _openNewReclamation,
              child: const Text('Créer une réclamation'),
            ),
          ],
        ),
      )
          : Column(
        children: recent.map((r) => _RecentRow(
          reclamation: r,
          dateLabel: _formatDateShort(r.createdAt),
          onTap: () => _openDetail(r),
        )).toList(),
      ),
    );
  }
}

enum _ChartType { bar, line }

class _KpiDef {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color light;

  const _KpiDef(this.label, this.value, this.icon, this.color, this.light);
}

class _KpiCard extends StatelessWidget {
  final _KpiDef kpi;
  final bool compact;
  const _KpiCard({required this.kpi, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 30.0 : 36.0;
    final valueSize = compact ? 20.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: context.dashCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dashCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(color: kpi.light, borderRadius: BorderRadius.circular(9)),
            child: Icon(kpi.icon, color: kpi.color, size: compact ? 18 : 20),
          ),
          SizedBox(height: compact ? 6 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.value,
              style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w700, height: 1, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.label,
            style: TextStyle(fontSize: compact ? 10 : 11, color: context.dashTextMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _ThemeCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.dashCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dashCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, style: TextStyle(fontSize: 11, color: context.dashTextMuted)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: context.dashCardBorder),
          child,
        ],
      ),
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final _ChartType chartType;
  final ValueChanged<_ChartType> onChanged;

  const _ChartToggle({required this.chartType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.dashToggleBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(context, 'Barres', _ChartType.bar, primary),
          _toggleBtn(context, 'Courbe', _ChartType.line, primary),
        ],
      ),
    );
  }

  Widget _toggleBtn(BuildContext context, String label, _ChartType type, Color primary) {
    final active = chartType == type;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    return GestureDetector(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active ? [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : inactiveColor,
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final ReclamationModel reclamation;
  final String dateLabel;
  final VoidCallback onTap;

  const _RecentRow({required this.reclamation, required this.dateLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _DashColors.statusColor(reclamation.status);
    final ref = reclamation.referenceNumber.isNotEmpty
        ? reclamation.referenceNumber
        : '#${reclamation.id}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.dashDivider)),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      reclamation.module.name.isNotEmpty ? reclamation.module.name : reclamation.type,
                      style: TextStyle(fontSize: 11, color: context.dashTextMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.27)),
                    ),
                    child: Text(
                      _DashColors.statusLabel(reclamation.status),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(dateLabel, style: TextStyle(fontSize: 10, color: context.dashTextMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}