import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';
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
                children: [
                  StudentDashboard(
                    embedded: true,
                    onNewReclamation: () => setState(() => _selectedIndex = 2),
                    onViewAllReclamations: () => setState(() => _selectedIndex = 1),
                  ),
                  const ReclamationScreen(),
                  const CreateReclamationScreen(),
                  const NotificationScreen(),
                  const ProfileScreen(),
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
