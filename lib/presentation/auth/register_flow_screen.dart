import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1; // 1: Identity, 2: OTP Validation, 3: Account Creation
  bool _isLoading = false;

  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _processIdentityStep() async {
    if (_matriculeController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showError('الرجاء تعبئة كافة الحقول المطلوبة');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final dynamic identityResult = await ApiConfig().authService.verifyIdentity(
        matricule: _matriculeController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (identityResult != null) {
        if (identityResult is String) {
          setState(() => _isLoading = false);
          _showError(identityResult);
          return;
        }

        if (identityResult is Map && identityResult['success'] == true) {
          final dynamic otpResult = await ApiConfig().authService.sendRegistrationOtp(_emailController.text.trim());

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (otpResult is Map && otpResult['success'] == true) {
            setState(() => _currentStep = 2);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال كود التفعيل إلى بريدك الإلكتروني'), backgroundColor: Colors.green),
            );
          } else {
            String errMsg = (otpResult is Map) ? (otpResult['message'] ?? 'فشل إرسال كود التفعيل') : otpResult.toString();
            _showError(errMsg);
          }
        } else {
          setState(() => _isLoading = false);
          String errMsg = (identityResult is Map) ? (identityResult['message'] ?? 'البيانات غير مطابقة لسجلات المعهد') : 'البيانات غير مطابقة';
          _showError(errMsg);
        }
      } else {
        setState(() => _isLoading = false);
        _showError('لم يتم استقبال رد من السيرفر');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ غير متوقع: $e');
    }
  }

  void _processOtpStep() async {
    if (_otpController.text.trim().length < 6) {
      _showError('الرجاء إدخال الرمز المكون من 6 أرقام كاملاً');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final dynamic result = await ApiConfig().authService.verifyRegistrationOtp(
        email: _emailController.text.trim(),
        otpCode: _otpController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result != null) {
        if (result is String) {
          _showError(result);
          return;
        }

        if (result is Map && result['success'] == true) {
          setState(() => _currentStep = 3);
        } else {
          String errMsg = (result is Map) ? (result['message'] ?? 'رمز التحقق خاطئ أو منتهي') : 'الرمز غير صحيح';
          _showError(errMsg);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('خطأ أثناء فحص الرمز: $e');
    }
  }

  void _processFinalRegister() async {
    if (_nameController.text.trim().isEmpty || _passwordController.text.length < 8) {
      _showError('يرجى التحقق من الاسم وقوة كلمة المرور (8 أحرف على الأقل)');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمات المرور غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dynamic result = await ApiConfig().authService.registerStudent(
        matricule: _matriculeController.text.trim(),
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result != null) {
        if (result is String) {
          _showError(result);
          return;
        }

        if (result is Map && (result['success'] == true || result['token'] != null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تهانينا! تم إنشاء حسابك الأكاديمي بنجاح'), backgroundColor: Colors.green),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else {
          String errMsg = (result is Map) ? (result['message'] ?? 'فشل إتمام التسجيل') : 'حدث خطأ غير متوقع';
          _showError(errMsg);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('خطأ أثناء إتمام العملية: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('طالب جديد - خطوة $_currentStep من 3', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: _buildFlowWidget(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowWidget() {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text('التحقق من الهوية الأكاديمية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('أدخل رقم التسجيل والإيميل المعتمدين لدى إدارة المعهد لتأكيد قيدك', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              controller: _matriculeController,
              decoration: const InputDecoration(labelText: 'رقم التسجيل / Matricule', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني للأكاديمية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _processIdentityStep,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.blueGrey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تحقق والانتقال للخطوة التالية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('تأكيد ملكية البريد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('أدخل كود التفعيل المكون من 6 أرقام المرسل إلى:\n${_emailController.text}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'رمز التفعيل (OTP)', border: OutlineInputBorder(), counterText: ""),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _processOtpStep,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تأكيد الرمز والتالي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text('إعداد بيانات الحساب الشخصي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل للطالب', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة (8 أحرف على الأقل)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock_outlined)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _processFinalRegister,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('إنشاء الحساب والولوج للتطبيق', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}