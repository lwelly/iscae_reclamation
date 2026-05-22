import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import 'widgets/auth_shared.dart';

// Définition locale de la charte graphique ISCAE
class IscaeColors {
  static const Color green = Color(0xFF0B8243);      // Vert texte/flèche
  static const Color cyanDark = Color(0xFF4A7479);   // Bleu-gris de la sphère
  static const Color cyanLight = Color(0xFF79C2C4);  // Bleu-cyan clair de la sphère
  static const Color white = Color(0xFFFFFFFF);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanDark, cyanLight],
  );
}

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
  final _otpKey = GlobalKey<OtpInputRowState>();
  bool _isLoading = false;
  String _errorMsg = '';

  void _verifyOtp() async {
    final otpCode = _otpKey.currentState?.value ?? '';

    setState(() => _errorMsg = '');

    if (otpCode.length < 6) {
      setState(() => _errorMsg = 'Veuillez saisir le code complet à 6 chiffres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dynamic result = await ApiConfig().authService.verifyDeviceOtp(
        userId: widget.userId,
        otpCode: otpCode,
        deviceFingerprint: "flutter_app_device_fingerprint_xyz",
      );

      setState(() => _isLoading = false);

      if (result != null) {
        if (!mounted) return;

        if (result is String) {
          setState(() => _errorMsg = result);
          _otpKey.currentState?.clear();
          return;
        }

        if (result is Map) {
          if (result['success'] == true || result['token'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('L\'appareil a été validé. Connexion établie avec succès.'),
                  backgroundColor: Colors.green
              ),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          } else {
            setState(() => _errorMsg = result['message'] ?? 'Le code de vérification est incorrect ou a expiré.');
            _otpKey.currentState?.clear();
          }
        }
      } else {
        if (!mounted) return;
        setState(() => _errorMsg = 'Le serveur n\'a pas répondu ; veuillez vérifier votre connexion.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'Erreur lors de la vérification: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: IscaeColors.brandGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 490),
                child: Column(
                  children: [
                    const AuthLogoCircle(size: 72, imageSize: 64),
                    const SizedBox(height: 12),
                    const Text(
                        'ISCAE',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    Text(
                      'Sécurisation de l\'accès',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8)
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: IscaeColors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14)
                                ),
                                child: const Icon(Icons.phonelink_lock, color: IscaeColors.green, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Nouvel appareil détecté',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                        'Veuillez valider votre identité pour continuer.',
                                        style: TextStyle(fontSize: 12, color: AuthColors.muted)
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text.rich(
                            TextSpan(
                              text: 'Un code OTP de sécurité a été envoyé à l\'adresse : \n',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                              children: [
                                TextSpan(
                                    text: widget.maskedEmail,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                                )
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const AuthFieldLabel('Code de vérification (6 chiffres)'),
                          OtpInputRow(
                              key: _otpKey,
                              enabled: !_isLoading,
                              onChanged: (_) => setState(() => _errorMsg = '')
                          ),
                          if (_errorMsg.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
                          ],
                          const SizedBox(height: 24),
                          Theme(
                            data: Theme.of(context).copyWith(
                              elevatedButtonTheme: ElevatedButtonThemeData(
                                style: ElevatedButton.styleFrom(backgroundColor: IscaeColors.green),
                              ),
                            ),
                            child: AuthPrimaryButton(
                              label: 'Confirmer l\'appareil',
                              icon: Icons.check_circle_outline,
                              loading: _isLoading,
                              onPressed: _verifyOtp,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, size: 14, color: IscaeColors.cyanDark),
                              label: const Text(
                                  'Retour',
                                  style: TextStyle(color: IscaeColors.cyanDark, fontSize: 13, fontWeight: FontWeight.w600)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© ${DateTime.now().year} ISCAE — Tous droits réservés',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}