import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import 'device_otp_screen.dart';
import '../student/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // إرسال طلب تسجيل الدخول مع برامتر البصمة
      final dynamic result = await ApiConfig().authService.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
        deviceFingerprint: "flutter_app_device_fingerprint_xyz",
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result != null) {
        // حماية الواجهة إذا عاد نص خطأ مباشر من السيرفر
        if (result is String) {
          _showError(result);
          return;
        }

        if (result is Map) {
          // الحالة الأولى: يحتاج التحقق من جهاز جديد
          if (result['requires_device_otp'] == true) {
            final int? userId = result['user_id'] != null
                ? int.tryParse(result['user_id'].toString())
                : (result['data'] != null ? int.tryParse(result['data']['user_id'].toString()) : null);

            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceOtpScreen(
                    userId: userId,
                    maskedEmail: result['masked_email'] ?? result['email'] ?? 'بريدك المسجل',
                  ),
                ),
              );
            } else {
              _showError('فشل قراءة معرف المستخدم من السيرفر');
            }
            return;
          }

          // الحالة الثانية: تسجيل الدخول القياسي بنجاح
          if (result['success'] == true || result['token'] != null) {
            // Sauvegarder le token
            if (result['token'] != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('auth_token', result['token']);
              ApiConfig().setAuthToken(result['token']);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تسجيل الدخول بنجاح!'), backgroundColor: Colors.green),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          } else {
            _showError(result['message'] ?? 'بيانات الاعتماد غير صحيحة');
          }
        }
      } else {
        _showError('لم يتم استقبال رد من السيرفر');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('خطأ أثناء المعالجة: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ISCAE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF5A7383), letterSpacing: 2),
                ),
                const Text(
                  'Espace Étudiant',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _loginController,
                  decoration: const InputDecoration(
                    labelText: 'Matricule / البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال رقم التسجيل أو الإيميل' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور / Mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال كلمة المرور' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A7383),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('طالب جديد؟ سجل حسابك الآن (Inscription)', style: TextStyle(color: Colors.blueGrey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text('نسيت كلمة المرور؟ (Mot de passe oublié)', style: TextStyle(color: Colors.blueGrey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}