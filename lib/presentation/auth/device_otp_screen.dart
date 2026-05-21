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
      final dynamic result = await ApiConfig().authService.verifyDeviceOtp(
        userId: widget.userId,
        otpCode: _otpController.text.trim(),
        deviceFingerprint: "flutter_app_device_fingerprint_xyz",
      );

      setState(() => _isLoading = false);

      if (result != null) {
        if (!mounted) return;

        if (result is String) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), backgroundColor: Colors.red),
          );
          return;
        }

        if (result is Map) {
          if (result['success'] == true || result['token'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lappareil a été documenté avec succès et la connexion a été établie avec succès.'), backgroundColor: Colors.green),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          } else {
            String errMsg = result['message'] ?? 'Le code de vérification est incorrect ou a expiré.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le serveur na pas répondu ; veuillez vérifier votre connexion.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la vérification: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation de l appareil', style: TextStyle(fontSize: 15)),
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
                const Icon(Icons.phonelink_lock, size: 72, color: Colors.blueGrey),
                const SizedBox(height: 24),
                const Text(
                  'Une connexion depuis un nouvel appareil a été détectée.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                Text(
                  'Un code de vérification (OTP) a été envoyé à votre adresse électronique enregistrée:\n${widget.maskedEmail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Saisissez le code de vérification (6 chiffres)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez saisir le code';
                    if (value.length < 6) return 'Vous devez saisir 6 chiffres complets.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
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
                      : const Text('Confirmation et connexion à lappareil', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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