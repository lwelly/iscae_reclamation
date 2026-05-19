import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/reclamation_model.dart';
import 'create_reclamation_screen.dart';
import 'reclamation_controller.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_ui_helpers.dart';

class ReclamationScreen extends StatefulWidget {
  const ReclamationScreen({super.key});

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  static const _perPage = 10;

  String _activeFilter = 'all';
  String _search = '';
  int _page = 1;
  final _searchController = TextEditingController();

  static const _filters = [
    _FilterDef('all', 'Toutes', Icons.format_list_bulleted),
    _FilterDef('pending', 'En attente', Icons.schedule_outlined),
    _FilterDef('resolved', 'Résolues', Icons.check_circle_outline),
    _FilterDef('rejected', 'Rejetées', Icons.cancel_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReclamationController>().fetchReclamations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, int> _counts(List<ReclamationModel> list) => {
        'all': list.length,
        'pending': list.where((r) => ReclamationUi.pendingStatuses.contains(r.status)).length,
        'resolved': list.where((r) => ReclamationUi.resolvedStatuses.contains(r.status)).length,
        'rejected': list.where((r) => r.status == 'rejected').length,
      };

  List<ReclamationModel> _filtered(List<ReclamationModel> list) {
    var res = list;
    switch (_activeFilter) {
      case 'pending':
        res = res.where((r) => ReclamationUi.pendingStatuses.contains(r.status)).toList();
        break;
      case 'resolved':
        res = res.where((r) => ReclamationUi.resolvedStatuses.contains(r.status)).toList();
        break;
      case 'rejected':
        res = res.where((r) => r.status == 'rejected').toList();
        break;
    }
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((r) {
        return r.referenceNumber.toLowerCase().contains(q) ||
            r.module.name.toLowerCase().contains(q) ||
            r.type.toLowerCase().contains(q);
      }).toList();
    }
    res.sort((a, b) {
      try {
        return DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt));
      } catch (_) {
        return 0;
      }
    });
    return res;
  }

  void _setFilter(String key) {
    setState(() {
      _activeFilter = key;
      _page = 1;
    });
  }

  void _goDetail(ReclamationModel r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReclamationDetailScreen(id: int.parse(r.id)),
      ),
    ).then((_) {
      if (mounted) context.read<ReclamationController>().fetchReclamations();
    });
  }

  Future<void> _openNew() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateReclamationScreen()),
    );
    if (mounted) context.read<ReclamationController>().fetchReclamations();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<ReclamationController>(
        builder: (context, controller, _) {
          final list = controller.reclamations;
          final filtered = _filtered(list);
          final totalPages = (filtered.length / _perPage).ceil().clamp(1, 9999);
          final safePage = _page.clamp(1, totalPages);
          if (safePage != _page) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _page = safePage);
            });
          }
          final paginated = filtered.skip((safePage - 1) * _perPage).take(_perPage).toList();
          final counts = _counts(list);

          return RefreshIndicator(
            onRefresh: () => controller.fetchReclamations(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // En-tête
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      '${list.length} réclamation${list.length > 1 ? 's' : ''} au total',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    FilledButton.icon(
                      onPressed: _openNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nouvelle réclamation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Toolbar : filtres + recherche
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filters.map((f) => _FilterChip(
                        label: f.label,
                        icon: f.icon,
                        count: counts[f.key] ?? 0,
                        active: _activeFilter == f.key,
                        onTap: () => _setFilter(f.key),
                      )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: context.appInputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _search = '';
                                _page = 1;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 1;
                  }),
                ),
                const SizedBox(height: 20),

                if (controller.isLoading)
                  _StateBox(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: primary, strokeWidth: 3),
                        const SizedBox(height: 12),
                        Text('Chargement de vos réclamations...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                else if (controller.errorMessage != null)
                  _StateBox(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 40),
                        const SizedBox(height: 12),
                        Text(controller.errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => controller.fetchReclamations(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else if (filtered.isEmpty)
                  _StateBox(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 12),
                        const Text('Aucune réclamation trouvée', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          _search.isNotEmpty
                              ? 'Aucun résultat pour votre recherche.'
                              : _activeFilter != 'all'
                                  ? 'Aucune réclamation dans cette catégorie.'
                                  : "Vous n'avez pas encore soumis de réclamation.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        if (_activeFilter == 'all' && _search.isEmpty) ...[
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: _openNew,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Soumettre une réclamation'),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useCards = constraints.maxWidth < 720;
                      if (useCards) {
                        return _ReclamationCardList(
                          rows: paginated,
                          totalFiltered: filtered.length,
                          page: safePage,
                          totalPages: totalPages,
                          onPageChanged: (p) => setState(() => _page = p),
                          onRowTap: _goDetail,
                        );
                      }
                      return _ReclamationTable(
                        rows: paginated,
                        totalFiltered: filtered.length,
                        page: safePage,
                        totalPages: totalPages,
                        onPageChanged: (p) => setState(() => _page = p),
                        onRowTap: _goDetail,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterDef {
  final String key;
  final String label;
  final IconData icon;
  const _FilterDef(this.key, this.label, this.icon);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final inactiveBg = context.appCard;
    final inactiveBorder = context.appBorder;
    final inactiveText = context.appMuted;
    return Material(
      color: active ? primary : inactiveBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? primary : inactiveBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: active ? Colors.white : inactiveText),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : context.appOnSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : context.appOnSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  final Widget child;
  const _StateBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Center(child: child),
    );
  }
}

class _ReclamationTable extends StatelessWidget {
  final List<ReclamationModel> rows;
  final int totalFiltered;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ReclamationModel> onRowTap;

  const _ReclamationTable({
    required this.rows,
    required this.totalFiltered,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: context.appSurfaceLow,
            child: const Row(
              children: [
                Expanded(flex: 2, child: _HeadCell('Référence')),
                Expanded(flex: 3, child: _HeadCell('Module')),
                Expanded(flex: 2, child: _HeadCell('Type')),
                Expanded(flex: 2, child: _HeadCell('Date')),
                Expanded(flex: 2, child: _HeadCell('Statut')),
                SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lignes
          ...rows.map((r) => _TableRow(reclamation: r, onTap: () => onRowTap(r))),
          _TableFooter(
            rowsCount: rows.length,
            totalFiltered: totalFiltered,
            page: page,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String text;
  const _HeadCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Liste en cartes pour mobile (évite le tableau illisible).
class _ReclamationCardList extends StatelessWidget {
  final List<ReclamationModel> rows;
  final int totalFiltered;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ReclamationModel> onRowTap;

  const _ReclamationCardList({
    required this.rows,
    required this.totalFiltered,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReclamationCard(reclamation: r, onTap: () => onRowTap(r)),
            )),
        _TableFooter(
          rowsCount: rows.length,
          totalFiltered: totalFiltered,
          page: page,
          totalPages: totalPages,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _ReclamationCard extends StatelessWidget {
  final ReclamationModel reclamation;
  final VoidCallback onTap;

  const _ReclamationCard({required this.reclamation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ref = reclamation.referenceNumber.isNotEmpty
        ? reclamation.referenceNumber
        : '#${reclamation.id}';
    final statusColor = ReclamationUi.statusColor(reclamation.status);

    return Material(
      color: context.appCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ref,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ReclamationUi.statusBg(reclamation.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ReclamationUi.statusLabel(reclamation.status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[500]),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                reclamation.module.name.isNotEmpty ? reclamation.module.name : '—',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ReclamationUi.typeBg(reclamation.type),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ReclamationUi.typeLabel(reclamation.type),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ReclamationUi.typeColor(reclamation.type),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${ReclamationUi.formatDateShort(reclamation.createdAt)} · ${ReclamationUi.formatTime(reclamation.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  final int rowsCount;
  final int totalFiltered;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _TableFooter({
    required this.rowsCount,
    required this.totalFiltered,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$rowsCount sur $totalFiltered réclamation${totalFiltered > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: context.appMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                ),
                Text('$page / $totalPages', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final ReclamationModel reclamation;
  final VoidCallback onTap;

  const _TableRow({required this.reclamation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ref = reclamation.referenceNumber.isNotEmpty
        ? reclamation.referenceNumber
        : '#${reclamation.id}';
    final statusColor = ReclamationUi.statusColor(reclamation.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ref,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  reclamation.module.name.isNotEmpty ? reclamation.module.name : '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ReclamationUi.typeBg(reclamation.type),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ReclamationUi.typeLabel(reclamation.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ReclamationUi.typeColor(reclamation.type),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReclamationUi.formatDateShort(reclamation.createdAt),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      ReclamationUi.formatTime(reclamation.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ReclamationUi.statusBg(reclamation.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          ReclamationUi.statusLabel(reclamation.status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}
