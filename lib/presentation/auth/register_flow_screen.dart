import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import 'widgets/auth_shared.dart';

// Définition locale de la charte graphique ISCAE
class IscaeColors {
  static const Color green = Color(0xFF0B8243);      // Vert texte/flèche
  static const Color cyanDark = Color(0xFF4A7479);   // Bleu-gris de la sphère
  static const Color cyanLight = Color(0xFF79C2C4);  // Bleu-cyan clair de la sphère
  static const Color white = Color(0xFFFFFFFF);

  // Dégradé officiel pour l'arrière-plan de l'application
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanDark, cyanLight],
  );
}

enum _LoginStep { login, deviceOtp }

class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> with ResendCooldownMixin {
  static const _steps = ['Identité', 'Vérification', 'Mot de passe'];

  int _step = 1;
  bool _loading = false;
  bool _showPwd = false;
  String _errorMsg = '';

  int? _studentId;
  String _maskedEmail = '';
  String _studentName = '';
  String _studentFiliere = '';
  String _studentNiveau = '';

  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputRowState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _redirectTimer;

  bool get _pwdMismatch =>
      _confirmPasswordController.text.isNotEmpty &&
          _passwordController.text != _confirmPasswordController.text;

  String _maskEmail(String email) {
    if (email.isEmpty) return '***@***.***';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final user = parts[0];
    final visible = user.length > 3 ? user.substring(0, 3) : user.substring(0, 1);
    return '$visible***@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      // Bloque le redimensionnement automatique pour éviter les sauts de layout et overflows
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: IscaeColors.brandGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              // Marges dynamiques réduites sur mobile pour économiser du layout vertical
              padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 16, vertical: wide ? 24 : 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Contraint la hauteur au strict nécessaire
                  children: [
                    AuthLogoCircle(size: wide ? 72 : 60, imageSize: wide ? 64 : 52),
                    SizedBox(height: wide ? 12 : 6),
                    Text('ISCAE', style: TextStyle(fontSize: wide ? 22 : 19, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      'Création de votre compte étudiant',
                      style: TextStyle(fontSize: wide ? 13 : 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    SizedBox(height: wide ? 24 : 14),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(wide ? 24 : 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_step < 4) _buildStepper(wide),
                          if (_step < 4) SizedBox(height: wide ? 24 : 14),
                          if (_errorMsg.isNotEmpty && _step < 4) ...[
                            AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
                            const SizedBox(height: 10),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: _buildStepContent(wide),
                          ),
                          if (_step < 4) ...[
                            SizedBox(height: wide ? 20 : 12),
                            Center(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Déjà un compte ? ', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                                    child: const Text('Se connecter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: IscaeColors.green)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: wide ? 16 : 10),
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

  Widget _buildStepper(bool wide) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final done = _step > lineIndex + 1;
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.only(bottom: wide ? 18 : 14),
              color: done ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final stepNum = stepIndex + 1;
        final active = _step == stepNum;
        final done = _step > stepNum;
        return Column(
          children: [
            Container(
              width: wide ? 32 : 26,
              height: wide ? 32 : 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? const Color(0xFF4CAF50)
                    : active
                    ? IscaeColors.green
                    : const Color(0xFFE0E0E0),
                boxShadow: active ? [BoxShadow(color: IscaeColors.green.withValues(alpha: 0.45), blurRadius: 10)] : null,
              ),
              child: Center(
                child: done
                    ? Icon(Icons.check, color: Colors.white, size: wide ? 16 : 13)
                    : Text(
                  '$stepNum',
                  style: TextStyle(
                    fontSize: wide ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : const Color(0xFF757575),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _steps[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
                color: done
                    ? const Color(0xFF4CAF50)
                    : active
                    ? IscaeColors.green
                    : const Color(0xFF757575),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(bool wide) {
    switch (_step) {
      case 1:
        return _buildStep1(wide: wide, key: const ValueKey(1));
      case 2:
        return _buildStep2(wide: wide, key: const ValueKey(2));
      case 3:
        return _buildStep3(wide: wide, key: const ValueKey(3));
      default:
        return _buildSuccess(key: const ValueKey(4));
    }
  }

  Widget _buildStep1({required bool wide, Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vérification de votre identité', style: TextStyle(fontSize: wide ? 15 : 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Saisissez votre matricule et votre email personnel tels qu\'enregistrés par l\'administration.',
          style: TextStyle(fontSize: wide ? 13 : 12, color: Colors.grey.shade600, height: 1.4),
        ),
        SizedBox(height: wide ? 20 : 12),
        const AuthFieldLabel('Matricule *'),
        AuthTextField(
          controller: _matriculeController,
          hint: 'Votre matricule',
          prefixIcon: Icons.badge_outlined,
          enabled: !_loading,
        ),
        SizedBox(height: wide ? 16 : 10),
        const AuthFieldLabel('Email personnel *'),
        AuthTextField(
          controller: _emailController,
          hint: 'votre.email@gmail.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: !_loading,
        ),
        const SizedBox(height: 4),
        Text(
          'Saisissez votre adresse email personnelle (Gmail, Hotmail, etc.)',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        SizedBox(height: wide ? 24 : 16),
        Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: IscaeColors.green),
            ),
          ),
          child: AuthPrimaryButton(
            label: 'Vérifier mon identité',
            icon: Icons.verified_user_outlined,
            loading: _loading,
            onPressed: _handleVerifyIdentity,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2({required bool wide, Key? key}) {
    final filiereNiveau = [
      if (_studentFiliere.isNotEmpty) _studentFiliere,
      if (_studentFiliere.isNotEmpty && _studentNiveau.isNotEmpty) ' — ',
      if (_studentNiveau.isNotEmpty) _studentNiveau,
    ].join();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vérification par email', style: TextStyle(fontSize: wide ? 15 : 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: 'Un code à 6 chiffres a été envoyé à ',
            style: TextStyle(fontSize: wide ? 13 : 12, color: Colors.grey.shade600),
            children: [TextSpan(text: _maskedEmail, style: const TextStyle(fontWeight: FontWeight.bold))],
          ),
        ),
        SizedBox(height: wide ? 16 : 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: IscaeColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, color: IscaeColors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    if (filiereNiveau.isNotEmpty)
                      Text(filiereNiveau, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: wide ? 20 : 12),
        const AuthFieldLabel('Code à 6 chiffres'),
        OtpInputRow(key: _otpKey, enabled: !_loading, onChanged: (_) => setState(() => _errorMsg = '')),
        SizedBox(height: wide ? 16 : 10),
        Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: IscaeColors.green),
            ),
          ),
          child: AuthPrimaryButton(
            label: 'Vérifier le code',
            icon: Icons.shield_outlined,
            loading: _loading,
            onPressed: _handleVerifyOtp,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: SizedBox(
            height: 32,
            child: TextButton(
              onPressed: (resendCooldown > 0 || _loading) ? null : _handleResendOtp,
              child: Text(
                resendCooldown > 0 ? 'Renvoyer dans ${resendCooldown}s' : 'Renvoyer le code',
                style: const TextStyle(color: IscaeColors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3({required bool wide, Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Définir votre mot de passe', style: TextStyle(fontSize: wide ? 15 : 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Choisissez un mot de passe sécurisé pour votre compte.', style: TextStyle(fontSize: wide ? 13 : 12, color: Colors.grey.shade600)),
        SizedBox(height: wide ? 20 : 12),
        const AuthFieldLabel('Mot de passe *'),
        AuthTextField(
          controller: _passwordController,
          hint: 'Minimum 8 caractères',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          suffix: IconButton(
            icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _showPwd = !_showPwd),
          ),
        ),
        SizedBox(height: wide ? 16 : 10),
        const AuthFieldLabel('Confirmer le mot de passe *'),
        AuthTextField(
          controller: _confirmPasswordController,
          hint: 'Répétez le mot de passe',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          onChanged: (_) => setState(() {}),
        ),
        if (_pwdMismatch)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Les mots de passe ne correspondent pas.', style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
          ),
        SizedBox(height: wide ? 24 : 16),
        Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: IscaeColors.green),
            ),
          ),
          child: AuthPrimaryButton(
            label: 'Créer mon compte',
            icon: Icons.check_circle_outline,
            loading: _loading,
            onPressed: _handleSetPassword,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess({Key? key}) {
    return Column(
      key: key,
      children: [
        const Icon(Icons.check_circle, size: 64, color: Color(0xFF4CAF50)),
        const SizedBox(height: 14),
        const Text('Compte créé avec succès !', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: 'Bienvenue ',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            children: [
              TextSpan(text: _studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '. Redirection...'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const LinearProgressIndicator(color: Color(0xFF4CAF50), borderRadius: BorderRadius.all(Radius.circular(4))),
      ],
    );
  }

  Future<void> _handleVerifyIdentity() async {
    setState(() => _errorMsg = '');
    final matricule = _matriculeController.text.trim().toUpperCase();
    final email = _emailController.text.trim().toLowerCase();
    if (matricule.isEmpty || email.isEmpty) {
      setState(() => _errorMsg = 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiConfig().authService.verifyIdentity(matricule: matricule, email: email);
      if (!mounted) return;

      if (result is String) {
        setState(() {
          _loading = false;
          _errorMsg = result;
        });
        return;
      }
      if (result is! Map) {
        setState(() {
          _loading = false;
          _errorMsg = 'Réponse serveur invalide.';
        });
        return;
      }

      final data = dataFromApiResult(result) ?? Map<String, dynamic>.from(result);
      final studentId = data['student_id'];
      if (studentId == null) {
        setState(() {
          _loading = false;
          _errorMsg = messageFromApiResult(result) ?? 'Erreur de vérification.';
        });
        return;
      }

      final rawName = data['full_name']?.toString();
      final builtName = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();

      setState(() {
        _studentId = int.tryParse(studentId.toString());
        _maskedEmail = _maskEmail(data['email']?.toString() ?? email);
        _studentName = (rawName != null && rawName.isNotEmpty) ? rawName : (builtName.isNotEmpty ? builtName : 'Étudiant');
        _studentFiliere = data['filiere']?.toString() ?? '';
        _studentNiveau = data['niveau']?.toString() ?? '';
      });

      await _sendOtp();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Erreur : $e';
        });
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_studentId == null) return;
    try {
      await ApiConfig().authService.sendRegistrationOtp(
        studentId: _studentId!,
        email: _emailController.text.trim().toLowerCase(),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _loading = false;
      _step = 2;
    });
    startCooldown();
  }

  Future<void> _handleResendOtp() async {
    if (_studentId == null || resendCooldown > 0) return;
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      await ApiConfig().authService.sendRegistrationOtp(
        studentId: _studentId!,
        email: _emailController.text.trim().toLowerCase(),
      );
      startCooldown();
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Erreur renvoi OTP.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpKey.currentState?.value ?? '';
    setState(() => _errorMsg = '');
    if (otp.length < 6) {
      setState(() => _errorMsg = 'Veuillez saisir le code à 6 chiffres.');
      return;
    }
    if (_studentId == null) {
      setState(() => _errorMsg = 'Session expirée. Recommencez.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiConfig().authService.verifyRegistrationOtp(
        studentId: _studentId!,
        otpCode: otp,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (result is String) {
        setState(() => _errorMsg = result);
        _otpKey.currentState?.clear();
        return;
      }
      if (result is Map && (result['success'] == true || result['success'] == null)) {
        setState(() => _step = 3);
        return;
      }
      setState(() => _errorMsg = messageFromApiResult(result) ?? 'Code OTP invalide.');
      _otpKey.currentState?.clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Erreur : $e';
        });
      }
    }
  }

  Future<void> _handleSetPassword() async {
    setState(() => _errorMsg = '');
    if (_passwordController.text.length < 8) {
      setState(() => _errorMsg = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMsg = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (_studentId == null) {
      setState(() => _errorMsg = 'Session expirée. Recommencez.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiConfig().authService.registerStudent(
        studentId: _studentId!,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (result is String) {
        setState(() => _errorMsg = result);
        return;
      }
      if (result is! Map) {
        setState(() => _errorMsg = 'Réponse serveur invalide.');
        return;
      }

      final token = result['token']?.toString() ?? dataFromApiResult(result)?['token']?.toString();
      if (token == null || token.isEmpty) {
        setState(() => _errorMsg = 'Erreur : token manquant dans la réponse.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      ApiConfig().setAuthToken(token);

      setState(() => _step = 4);
      _redirectTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Erreur lors de la création du compte.';
        });
      }
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _matriculeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}