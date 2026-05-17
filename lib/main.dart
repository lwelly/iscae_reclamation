import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/api_config.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_flow_screen.dart';
import 'presentation/auth/forgot_password_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Récupérer le token stocké (si disponible)
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token');
  
  // Initialiser l'API avec le token
  ApiConfig().initialize(authToken: authToken);
  
  runApp(const IscaeApp());
}

class IscaeApp extends StatelessWidget {
  const IscaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISCAE Espace Étudiant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
        fontFamily: 'Cairo', // إذا كنت تستخدم خط كاييرو المفضل للواجهات العربية/الفرنسية
      ),
      // الشاشة الابتدائية للتطبيق هي شاشة تسجيل الدخول
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterFlowScreen(),
        '/forgot-password': (context) => const ForgotPasswordFlow(),
        '/dashboard': (context) => const DummyDashboardScreen(), // شاشة مؤقتة للاختبار
      },
    );
  }
}

// شاشة مؤقتة تظهر فقط عند نجاح تسجيل الدخول لتأكيد العبور
class DummyDashboardScreen extends StatelessWidget {
  const DummyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم - ISCAE')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'تم الاتصال بالسيرفر بنجاح!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('تسجيل الخروج'),
            )
          ],
        ),
      ),
    );
  }
}