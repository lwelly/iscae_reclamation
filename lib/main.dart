import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Configurations & Services
import 'core/config/api_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

// Controllers (Providers)
import 'presentation/student/dashboard_controller.dart';
import 'presentation/student/reclamation_controller.dart';
import 'presentation/student/notes_controller.dart';
import 'presentation/student/profile_controller.dart';
import 'presentation/student/notification_controller.dart';

// Écrans (Présentation)
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_flow_screen.dart';
import 'presentation/auth/forgot_password_flow.dart';
import 'presentation/student/main_layout_screen.dart'; // Ton nouveau layout avec Sidebar
import 'presentation/student/reclamation_screen.dart';
import 'presentation/student/profile_screen.dart';

void main() async {
  // S'assurer que les liaisons Flutter sont bien initialisées avant le code asynchrone
  WidgetsFlutterBinding.ensureInitialized();

  // Récupérer le token stocké (si disponible) au démarrage
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token');

  // Initialiser l'API avec le token récupéré
  ApiConfig().initialize(authToken: authToken);

  runApp(
    // Injection globale des contrôleurs pour toute l'application
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => ReclamationController()),
        ChangeNotifierProvider(create: (_) => NotesController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: const IscaeApp(),
    ),
  );
}

class IscaeApp extends StatelessWidget {
  const IscaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      title: 'ISCAE Espace Étudiant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeCtrl.themeMode,
      // On démarre systématiquement par le SplashScreen
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterFlowScreen(),
        '/forgot-password': (context) => const ForgotPasswordFlow(),
        '/dashboard': (context) => const MainLayoutScreen(), // Redirige vers le layout complet avec Sidebar
        '/reclamations': (context) => const ReclamationScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// Écran de chargement (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState(); // CORRIGÉ : Un seul underscore ici
}

class _SplashScreenState extends State<SplashScreen> { // CORRIGÉ : Un seul underscore ici
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Durée d'affichage du splash

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (!mounted) return;

    if (authToken != null && authToken.isNotEmpty) {
      // Si le token existe, direction le MainLayoutScreen (Sidebar + Dashboard)
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      // Sinon, direction la page de connexion
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F2547), // Fond bleu ISCAE pour le splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'ISCAE',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
            ),
            SizedBox(height: 10),
            Text(
              'Espace Étudiant',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}