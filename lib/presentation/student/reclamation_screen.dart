import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reclamation_controller.dart';
import '../../data/models/reclamation_model.dart';

class ReclamationScreen extends StatefulWidget {
  const ReclamationScreen({super.key});

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['all', 'submitted', 'received', 'resolved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReclamationController>().fetchReclamations();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _statuses[_tabController.index];
        context.read<ReclamationController>().fetchReclamations(status: status);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Réclamations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Soumises'),
            Tab(text: 'Reçues'),
            Tab(text: 'Résolues'),
            Tab(text: 'Rejetées'),
          ],
        ),
      ),
      body: Consumer<ReclamationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchReclamations(
                        status: _statuses[_tabController.index],
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.reclamations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => controller.fetchReclamations(status: _statuses[_tabController.index]),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune réclamation trouvée',
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchReclamations(status: _statuses[_tabController.index]),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.reclamations.length,
              itemBuilder: (context, index) {
                final reclamation = controller.reclamations[index];
                return _buildReclamationCard(context, reclamation, controller);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulaire de création à lier ici')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle réclamation'),
      ),
    );
  }

  Widget _buildReclamationCard(BuildContext context, ReclamationModel reclamation, ReclamationController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // CORRIGÉ : Conversion du String en int via int.parse()
          controller.fetchDetails(int.parse(reclamation.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reclamation.referenceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  _buildStatusBadge(reclamation.status),
                ],
              ),
              const Divider(height: 20),
              Text(
                reclamation.module.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.layers_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    reclamation.semestre.label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.assignment_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Type: ${reclamation.type.toUpperCase()}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Note Actuelle: '),
                        TextSpan(
                          text: '${reclamation.noteActuelle}/20',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                  if (reclamation.noteReclamee != null)
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          const TextSpan(text: 'Note Réclamée: '),
                          TextSpan(
                            text: '${reclamation.noteReclamee}/20',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (reclamation.status == 'submitted' || reclamation.status == 'received') ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showCancelDialog(context, reclamation, controller),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Annuler la demande', style: TextStyle(fontSize: 13)),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'submitted':
        backgroundColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blue[800]!;
        label = 'Soumis';
        break;
      case 'received':
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange[800]!;
        label = 'En cours';
        break;
      case 'resolved':
        backgroundColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green[800]!;
        label = 'Résolue';
        break;
      case 'rejected':
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red[800]!;
        label = 'Rejetée';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey[800]!;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ReclamationModel reclamation, ReclamationController controller) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: Text('Voulez-vous vraiment annuler la réclamation ${reclamation.referenceNumber} ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                // CORRIGÉ : Conversion du String en int via int.parse()
                final success = await controller.cancelReclamation(int.parse(reclamation.id));
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réclamation annulée avec succès.')),
                  );
                }
              },
              child: const Text('Confirmer l\'annulation', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}