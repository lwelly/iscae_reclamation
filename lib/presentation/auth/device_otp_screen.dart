import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

class DeviceOtpScreen extends StatefulWidget {
  final int userId;
  final String maskedEmail;

  const DeviceOtpScreen({
    super.key,
    required this.userId,
    required this.maskedEmail,
  });

  @override
  State<DeviceOtpScreen> createState() => _DeviceOtpScreenState();
}

class _DeviceOtpScreenState extends State<DeviceOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // استدعاء دالة التحقق verifyDeviceOtp مع تمرير الـ deviceFingerprint المطلوبة إجبارياً
      final dynamic result = await ApiConfig().authService.verifyDeviceOtp(
        userId: widget.userId,
        otpCode: _otpController.text.trim(),
        deviceFingerprint: "flutter_app_device_fingerprint_xyz", // نفس البصمة المستخدمة في شاشة الدخول
      );

      setState(() => _isLoading = false);

      if (result != null) {
        if (!mounted) return;

        // حماية الواجهة في حال رجوع رسالة نصية مباشرة عند الخطأ
        if (result is String) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), backgroundColor: Colors.red),
          );
          return;
        }

        // المعالجة الآمنة في حال رجوع مصفوفة Map (الرد القياسي من لارافيل)
        if (result is Map) {
          if (result['success'] == true || result['token'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم توثيق الجهاز والدخول بنجاح!'), backgroundColor: Colors.green),
            );
            // الانتقال إلى الشاشة الرئيسية للتطبيق (Dashboard) وتصفير مكدس الشاشات
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          } else {
            String errMsg = result['message'] ?? 'كود التحقق غير صحيح أو منتهي الصلاحية';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('السيرفر لم يرسل استجابة، تحقق من الاتصال'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء التحقق: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق الجهاز'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.phonelink_lock, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 24),
                const Text(
                  'تم رصد تسجيل دخول من جهاز جديد',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                Text(
                  'تم إرسال كود التحقق (OTP) إلى بريدك الإلكتروني المعتمد:\n${widget.maskedEmail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // حقل كود الـ OTP
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'أدخل رمز التحقق (6 أرقام)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال الرمز';
                    if (value.length < 6) return 'يجب إدخال 6 أرقام كاملة';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // زر التأكيد
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('تأكيد الجهاز ودخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    _otpController.dispose();
    super.dispose();
  }
}