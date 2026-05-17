import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  int _currentStep = 1; // 1: Email, 2: OTP, 3: Reset Password
  bool _isLoading = false;
  int? _userId;
  String? _resetToken;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _sendOtp() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final dynamic result = await ApiConfig().authService.forgotPassword(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Map && result['success'] == true) {
      setState(() {
        _userId = result['user_id'] != null
            ? int.tryParse(result['user_id'].toString())
            : (result['data'] != null ? int.tryParse(result['data']['user_id'].toString()) : null);
        _currentStep = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال كود استعادة كلمة المرور'), backgroundColor: Colors.green),
      );
    } else {
      String msg = (result is Map) ? (result['message'] ?? 'البريد غير مسجل لدينا') : result.toString();
      _showError(msg);
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.trim().isEmpty || _userId == null) return;
    setState(() => _isLoading = true);

    // تمرير المعاملات كـ Positional Arguments كما تم تعريفها بالسيرفس
    final dynamic result = await ApiConfig().authService.forgotVerifyOtp(
      _userId!,
      _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Map && result['success'] == true) {
      setState(() {
        _resetToken = result['reset_token'] != null
            ? result['reset_token'].toString()
            : (result['data'] != null ? result['data']['reset_token']?.toString() : null);
        _currentStep = 3;
      });
    } else {
      String msg = (result is Map) ? (result['message'] ?? 'رمز التحقق غير صحيح') : result.toString();
      _showError(msg);
    }
  }

  void _resetPassword() async {
    if (_passwordController.text.length < 8) {
      _showError('يجب أن تكون كلمة المرور 8 أحرف على الأقل');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمات المرور غير متطابقة');
      return;
    }
    if (_resetToken == null) return;

    setState(() => _isLoading = true);

    final dynamic result = await ApiConfig().authService.resetPassword(
      resetToken: _resetToken!,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Map && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // العودة لشاشة تسجيل الدخول
    } else {
      String msg = (result is Map) ? (result['message'] ?? 'فشل تحديث كلمة المرور') : result.toString();
      _showError(msg);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('استعادة كلمة المرور - خطوة $_currentStep')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const CircularProgressIndicator();

    switch (_currentStep) {
      case 1:
        return Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني للأكاديمية', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _sendOtp, child: const Text('إرسال رمز التحقق')),
          ],
        );
      case 2:
        return Column(
          children: [
            TextField(controller: _otpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أدخل كود التحقق (OTP)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _verifyOtp, child: const Text('تأكيد الرمز')),
          ],
        );
      case 3:
        return Column(
          children: [
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _resetPassword, child: const Text('تحديث كلمة المرور')),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}