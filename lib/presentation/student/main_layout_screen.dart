import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../auth/login_screen.dart';
import 'dashboard_controller.dart';
import 'reclamation_screen.dart';
import 'create_reclamation_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0; // 0 = Tableau de bord, 1 = Mes Réclamations, etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ================= SIDEBAR GAUCHE (FIXE) =================
          Container(
            width: 260,
            color: const Color(0xFF0F2547), // Bleu foncé ISCAE
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Header ISCAE
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.school, color: Color(0xFF0F2547)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISCAE',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          Text(
                            'Espace Étudiant',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Section Navigation
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),

                _buildSidebarItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', index: 0),
                _buildSidebarItem(icon: Icons.assignment_outlined, label: 'Mes Réclamations', index: 1),
                _buildSidebarItem(icon: Icons.add_circle_outline, label: 'Nouvelle Réclamation', index: 2),
                _buildSidebarItem(icon: Icons.notifications_none, label: 'Notifications', index: 3),

                const SizedBox(height: 20),

                // Section Compte
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'COMPTE',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                _buildSidebarItem(icon: Icons.person_outline, label: 'Mon Profil', index: 4),

                const Spacer(),

                // Déconnexion
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Déconnexion', style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('auth_token');
                    ApiConfig().clearAuthToken();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ================= CONTENU DYNAMIQUE (DROITE) =================
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  StudentDashboardContent(),               // Index 0
                  ReclamationScreen(),                     // Index 1
                  CreateReclamationScreen(),               // Index 2
                  NotificationScreen(),                    // Index 3
                  ProfileScreen(),                         // Index 4
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          hoverColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

// ================= VUE COMPOSANTE : DASHBOARD CONTENT =================
class StudentDashboardContent extends StatefulWidget {
  const StudentDashboardContent({super.key});

  @override
  State<StudentDashboardContent> createState() => _StudentDashboardContentState();
}

class _StudentDashboardContentState extends State<StudentDashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError) {
          return Center(child: Text('Erreur: ${controller.errorMessage}'));
        }

        final dashboard = controller.dashboard;
        final semestres = controller.semestres;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
                'Bonjour, Étudiant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)
            ),
            actions: [
              IconButton(icon: const Icon(Icons.dark_mode_outlined, color: Colors.black54), onPressed: () {}),
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black54), onPressed: () {}),
              const SizedBox(width: 12),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => controller.loadAllData(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  "Dimanche 17 Mai 2026",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _buildWebStatCard('Total', '${dashboard?.totalReclamations ?? 0}', Colors.blue, Icons.assignment_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildWebStatCard('En attente', '${dashboard?.pendingReclamations ?? 0}', Colors.orange, Icons.access_time)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildWebStatCard('Résolues', '${dashboard?.resolvedReclamations ?? 0}', Colors.green, Icons.check_circle_outline)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildWebStatCard('Rejetées', '${dashboard?.rejectedReclamations ?? 0}', Colors.red, Icons.cancel_outlined)),
                  ],
                ),
                const SizedBox(height: 32),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Semestres Disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (semestres.isEmpty)
                          const Text('Aucun semestre disponible')
                        else
                          ...semestres.map((semestre) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${semestre.code} - ${semestre.label}'),
                            trailing: const Icon(Icons.chevron_right),
                          )),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            )
          ],
        ),
      ),
    );
  }
}