// Exemple de configuration main.dart pour l'intégration API Student

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/api_config.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/student/dashboard_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Récupérer le token stocké (si disponible)
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token');
  
  // Initialiser l'API avec le token
  ApiConfig().initialize(authToken: authToken);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISCAE Student',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash screen duration
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    
    if (!mounted) return;
    
    if (authToken != null && authToken.isNotEmpty) {
      // Token existe, naviguer vers le dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
    } else {
      // Pas de token, naviguer vers login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'ISCAE',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


// Exemple d'écran Dashboard avec le contrôleur
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.loadAllData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Naviguer vers les notifications
            },
          ),
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Déconnexion
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              ApiConfig().clearAuthToken();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.hasError) {
            return Center(
              key: const Key('error_center'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${_controller.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.loadAllData(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return _buildDashboardContent();
        },
      ),
    );
  }

  Widget _buildDashboardContent() {
    final dashboard = _controller.dashboard;
    final semestres = _controller.semestres;
    final notifications = _controller.notifications;

    return RefreshIndicator(
      key: const Key('refresh_indicator'),
      onRefresh: () => _controller.loadAllData(),
      child: ListView(
        key: const Key('dashboard_list'),
        padding: const EdgeInsets.all(16),
        children: [
          // Section Réclamations
          Card(
            key: const Key('reclamations_card'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes Réclamations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', dashboard?.totalReclamations ?? 0, Colors.blue),
                      _buildStatItem('En attente', dashboard?.pendingReclamations ?? 0, Colors.orange),
                      _buildStatItem('Résolues', dashboard?.resolvedReclamations ?? 0, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section Notifications
          Card(
            key: const Key('notifications_card'),
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
                      if (_controller.notificationCounts != null)
                        Chip(
                          label: Text('${_controller.notificationCounts!['unread'] ?? 0}'),
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    const Text('Aucune notification')
                  else
                    ListView.builder(
                      key: const Key('notifications_list_builder'),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: notifications.take(3).length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return ListTile(
                          leading: Icon(
                            notification.isRead ? Icons.check_circle : Icons.notifications,
                            color: notification.isRead ? Colors.grey : Colors.blue,
                          ),
                          title: Text(notification.title),
                          subtitle: notification.message != null 
                              ? Text(notification.message!, maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          onTap: () {
                            _controller.markNotificationAsRead(notification.id);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section Semestres
          Card(
            key: const Key('semestres_card'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semestres Disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (semestres.isEmpty)
                    const Text('Aucun semestre disponible')
                  else
                    ListView.builder(
                      key: const Key('semestres_list_builder'),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: semestres.length,
                      itemBuilder: (context, index) {
                        final semestre = semestres[index];
                        return ListTile(
                          leading: const Icon(Icons.book),
                          title: Text('${semestre.code} - ${semestre.label}'),
                          subtitle: Text(semestre.availableTypes.join(', ')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Naviguer vers les détails du semestre
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      key: Key('stat_item_$label'),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

