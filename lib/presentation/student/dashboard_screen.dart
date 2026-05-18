import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_controller.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    // Charger les données via le Provider
    Future.microtask(() => context.read<DashboardController>().loadAllData());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    return Scaffold(
      key: const Key('dashboard_scaffold'),
      appBar: AppBar(
        key: const Key('dashboard_appbar'),
        title: const Text('Dashboard Étudiant'),
        actions: [
          IconButton(
            key: const Key('notifications_button'),
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Naviguer vers l'écran des notifications
            },
          ),
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              ApiConfig().clearAuthToken();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.hasError) {
            return Center(
              key: const Key('error_center'),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${controller.errorMessage}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => controller.loadAllData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildDashboardContent(controller);
        },
      ),
    );
  }

  Widget _buildDashboardContent(DashboardController controller) {
    final dashboard = controller.dashboard;
    if (dashboard == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return RefreshIndicator(
      key: const Key('refresh_indicator'),
      onRefresh: () => controller.loadAllData(),
      child: ListView(
        key: const Key('dashboard_list'),
        padding: const EdgeInsets.all(16),
        children: [
          _buildStudentInfo(),
          const SizedBox(height: 16),
          _buildStatsGrid(dashboard),
          const SizedBox(height: 16),
          _buildReclamationsCard(dashboard),
          const SizedBox(height: 16),
          _buildNotificationsCard(dashboard),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Nom Étudiant',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Matricule: XXXXXX',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardModel dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3, // Améliore le ratio hauteur/largeur des tuiles
      children: [
        _buildStatItem('Réclamations', dashboard.totalReclamations.toString(), Colors.blue),
        _buildStatItem('En attente', dashboard.pendingReclamations.toString(), Colors.orange),
        _buildStatItem('Résolues', dashboard.resolvedReclamations.toString(), Colors.green),
        _buildStatItem('Rejetées', dashboard.rejectedReclamations.toString(), Colors.red),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        key: Key('stat_item_$label'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReclamationsCard(DashboardModel dashboard) {
    return Card(
      key: const Key('reclamations_card'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Réclamations Récentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Naviguer vers la liste complète des réclamations
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const Divider(),
            if (dashboard.totalReclamations == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Aucune réclamation enregistrée'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dashboard.totalReclamations > 3 ? 3 : dashboard.totalReclamations,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.description, color: Colors.blue),
                    ),
                    title: Text('Réclamation N° ${index + 1}'),
                    subtitle: const Text('Statut: En cours d\'examen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Naviguer vers le détail de la réclamation
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard(DashboardModel dashboard) {
    return Card(
      key: const Key('notifications_card'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (dashboard.unreadNotifications > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dashboard.unreadNotifications} non lue(s)',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(),
            if (dashboard.unreadNotifications == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Aucune notification non lue'),
              )
            else
              ListView.separated(
                key: const Key('notifications_list_builder'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dashboard.unreadNotifications > 3 ? 3 : dashboard.unreadNotifications,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notification_important, color: Colors.amber),
                    title: Text('Notification de test ${index + 1}'),
                    subtitle: Text('Il y a ${index + 1} heure(s)'),
                    onTap: () {
                      // TODO: Action clic notification
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}