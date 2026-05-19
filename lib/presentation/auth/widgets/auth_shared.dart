import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';

const kIscaeLogoUrl =
    'https://th.bing.com/th/id/R.bb2cf5d4b7c5c26926598d033caa12d5?rik=qVW4UwQbTi2FBw&riu=http%3a%2f%2fiscae.mr%2fsites%2fdefault%2ffiles%2flogo-iscae.png';

const kDeviceFingerprint = 'flutter_app_device_fingerprint_xyz';

class AuthColors {
  static const formBg = Color(0xFFF0F4FF);
  static const forgotBg = Color(0xFFF8FAFC);
  static const title = Color(0xFF1A237E);
  static const primary = Color(0xFF3949AB);
  static const label = Color(0xFF37474F);
  static const muted = Color(0xFF78909C);
  static const fieldBg = Color(0xFFF8FAFF);
  static const fieldBorder = Color(0xFFE3E8F7);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
  );

  static const forgotBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
  );
}

/// Panneau gauche branding (login).
class AuthBrandingPanel extends StatelessWidget {
  const AuthBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AuthColors.brandGradient),
      child: Stack(
        children: [
          const _DecoCircle(size: 300, top: -80, right: -80),
          const _DecoCircle(size: 200, bottom: 60, left: -60),
          const _DecoCircle(size: 120, bottom: 200, right: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthLogoCircle(size: 100, imageSize: 88),
                  const SizedBox(height: 24),
                  const Text(
                    'ISCAE',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Institut Supérieur de Comptablite\net d'Administration des Entreprises",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Plateforme de gestion des réclamations étudiantes.\n'
                    'Soumettez, suivez et résolvez vos réclamations en toute simplicité.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.65), height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panneau gauche avec aperçu des étapes (mot de passe oublié).
class AuthForgotBrandingPanel extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBackToLogin;

  const AuthForgotBrandingPanel({
    super.key,
    required this.currentStep,
    required this.onBackToLogin,
  });

  static const _steps = [
    _PreviewStep(Icons.email_outlined, '#a5b4fc', '#6366f1', 'Vérification email', 'Confirmez votre identité'),
    _PreviewStep(Icons.vpn_key_outlined, '#fcd34d', '#f59e0b', 'Code de sécurité', 'OTP valable 10 minutes'),
    _PreviewStep(Icons.lock_reset, '#6ee7b7', '#10b981', 'Nouveau mot de passe', 'Créez un mot de passe sécurisé'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AuthColors.forgotBrandGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthLogoCircle(size: 92, imageSize: 74),
                  const SizedBox(height: 20),
                  const Text('ISCAE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    "Institut Supérieur de Comptabilité et d'Administration des Entreprises",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(_steps.length, (i) {
                    final s = _steps[i];
                    final stepNum = i + 1;
                    final active = currentStep == stepNum;
                    final done = currentStep > stepNum;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: active ? Color(int.parse(s.bgActive.replaceFirst('#', '0xFF'))) : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: Icon(s.icon, color: active || done ? Colors.white : Color(int.parse(s.color.replaceFirst('#', '0xFF'))), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  Text(s.desc, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                                ],
                              ),
                            ),
                            if (done) const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: onBackToLogin,
                    icon: Icon(Icons.arrow_back, size: 14, color: Colors.white.withValues(alpha: 0.55)),
                    label: Text('Retour à la connexion', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStep {
  final IconData icon;
  final String color;
  final String bgActive;
  final String title;
  final String desc;
  const _PreviewStep(this.icon, this.color, this.bgActive, this.title, this.desc);
}

class AuthLogoCircle extends StatelessWidget {
  final double size;
  final double imageSize;

  const AuthLogoCircle({super.key, required this.size, required this.imageSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: ClipOval(
        child: Image.network(
          kIscaeLogoUrl,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.school, size: imageSize * 0.5, color: Colors.white),
        ),
      ),
    );
  }
}

class _DecoCircle extends StatelessWidget {
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _DecoCircle({required this.size, this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}

/// Carte formulaire blanche arrondie.
class AuthFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthFormCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
                BoxShadow(color: AuthColors.title.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 12)),
              ],
        border: Border.all(color: isDark ? context.appBorder : AuthColors.title.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appOnSurface, letterSpacing: 0.3),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: Color(0xFF263238)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade500, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: AuthColors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuthColors.fieldBorder, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuthColors.fieldBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;
  final List<Color>? gradient;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? const [Color(0xFF1A237E), Color(0xFF3949AB)];
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const AuthErrorBanner({super.key, required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: Colors.red.shade900, fontSize: 13))),
          InkWell(onTap: onClose, child: Icon(Icons.close, size: 18, color: Colors.red.shade400)),
        ],
      ),
    );
  }
}

/// Saisie OTP 6 chiffres.
class OtpInputRow extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool enabled;

  const OtpInputRow({super.key, required this.onChanged, this.enabled = true});

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  String get value => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    widget.onChanged('');
    _focusNodes.first.requestFocus();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const digitCount = 6;
    const gap = 4.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = MediaQuery.sizeOf(context).width < 400;
    final fontSize = narrow ? 18.0 : 22.0;
    final borderColor = isDark ? const Color(0xFF334155) : AuthColors.fieldBorder;

    return Row(
      children: List.generate(digitCount, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : gap / 2, right: i == digitCount - 1 ? 0 : gap / 2),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: isDark ? Theme.of(context).colorScheme.onSurface : AuthColors.title,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF252536) : AuthColors.fieldBg,
                contentPadding: EdgeInsets.symmetric(vertical: narrow ? 10 : 12, horizontal: 2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AuthColors.primary, width: 1.5),
                ),
              ),
              onChanged: (v) {
                if (v.length == 1 && i < digitCount - 1) {
                  _focusNodes[i + 1].requestFocus();
                } else if (v.isEmpty && i > 0) {
                  _focusNodes[i - 1].requestFocus();
                }
                widget.onChanged(_controllers.map((c) => c.text).join());
              },
            ),
          ),
        );
      }),
    );
  }
}

/// Compte à rebours renvoi OTP (60s).
mixin ResendCooldownMixin<T extends StatefulWidget> on State<T> {
  int resendCooldown = 0;
  Timer? _cooldownTimer;

  void startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        resendCooldown--;
        if (resendCooldown <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}

String? messageFromApiResult(dynamic result) {
  if (result is Map) {
    return result['message']?.toString() ?? result['error']?.toString();
  }
  if (result is String) return result;
  return null;
}

Map<String, dynamic>? dataFromApiResult(dynamic result) {
  if (result is! Map) return null;
  final data = result['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return Map<String, dynamic>.from(result);
}
