import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import 'widgets/auth_shared.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    AuthLogoCircle(size: 72, imageSize: 64),
                    const SizedBox(height: 12),
                    const Text('ISCAE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      'Création de votre compte étudiant',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.15), blurRadius: 24, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_step < 4) _buildStepper(),
                          if (_step < 4) const SizedBox(height: 24),
                          if (_errorMsg.isNotEmpty && _step < 4) ...[
                            AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: _buildStepContent(),
                          ),
                          if (_step < 4) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Déjà un compte ? ', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  TextButton(
                                    onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                                    child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w600, color: AuthColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© ${DateTime.now().year} ISCAE — Tous droits réservés',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
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

  Widget _buildStepper() {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final done = _step > lineIndex + 1;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? const Color(0xFF4CAF50)
                    : active
                        ? const Color(0xFF1A237E)
                        : const Color(0xFFE0E0E0),
                boxShadow: active ? [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.45), blurRadius: 10)] : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '$stepNum',
                        style: TextStyle(
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
                fontSize: 11,
                fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
                color: done
                    ? const Color(0xFF4CAF50)
                    : active
                        ? const Color(0xFF1A237E)
                        : const Color(0xFF757575),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildStep1(key: const ValueKey(1));
      case 2:
        return _buildStep2(key: const ValueKey(2));
      case 3:
        return _buildStep3(key: const ValueKey(3));
      default:
        return _buildSuccess(key: const ValueKey(4));
    }
  }

  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Vérification de votre identité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Saisissez votre matricule et votre email personnel (Gmail, Hotmail, etc.) tels qu\'enregistrés par l\'administration.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 20),
        const AuthFieldLabel('Matricule *'),
        AuthTextField(
          controller: _matriculeController,
          hint: 'Votre matricule',
          prefixIcon: Icons.badge_outlined,
          enabled: !_loading,
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Email personnel *'),
        AuthTextField(
          controller: _emailController,
          hint: 'votre.email@gmail.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: !_loading,
        ),
        const SizedBox(height: 6),
        Text(
          'Saisissez votre adresse email personnelle (Gmail, Hotmail, etc.)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Vérifier mon identité',
          icon: Icons.verified_user_outlined,
          loading: _loading,
          onPressed: _handleVerifyIdentity,
        ),
      ],
    );
  }

  Widget _buildStep2({Key? key}) {
    final filiereNiveau = [
      if (_studentFiliere.isNotEmpty) _studentFiliere,
      if (_studentFiliere.isNotEmpty && _studentNiveau.isNotEmpty) ' — ',
      if (_studentNiveau.isNotEmpty) _studentNiveau,
    ].join();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Vérification par email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Un code à 6 chiffres a été envoyé à ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            children: [TextSpan(text: _maskedEmail, style: const TextStyle(fontWeight: FontWeight.bold))],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AuthColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, color: AuthColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (filiereNiveau.isNotEmpty)
                      Text(filiereNiveau, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AuthFieldLabel('Code à 6 chiffres'),
        OtpInputRow(key: _otpKey, enabled: !_loading, onChanged: (_) => setState(() => _errorMsg = '')),
        const SizedBox(height: 16),
        AuthPrimaryButton(
          label: 'Vérifier le code',
          icon: Icons.shield_outlined,
          loading: _loading,
          onPressed: _handleVerifyOtp,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: (resendCooldown > 0 || _loading) ? null : _handleResendOtp,
            child: Text(
              resendCooldown > 0 ? 'Renvoyer dans ${resendCooldown}s' : 'Renvoyer le code',
              style: const TextStyle(color: AuthColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Définir votre mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Choisissez un mot de passe sécurisé pour votre compte.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        const AuthFieldLabel('Mot de passe *'),
        AuthTextField(
          controller: _passwordController,
          hint: 'Minimum 8 caractères',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          suffix: IconButton(
            icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _showPwd = !_showPwd),
          ),
        ),
        const SizedBox(height: 16),
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
            padding: const EdgeInsets.only(top: 6),
            child: Text('Les mots de passe ne correspondent pas.', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Créer mon compte',
          icon: Icons.check_circle_outline,
          loading: _loading,
          onPressed: _handleSetPassword,
          gradient: const [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ],
    );
  }

  Widget _buildSuccess({Key? key}) {
    return Column(
      key: key,
      children: [
        const Icon(Icons.check_circle, size: 72, color: Color(0xFF4CAF50)),
        const SizedBox(height: 16),
        const Text('Compte créé avec succès !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Bienvenue ',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            children: [
              TextSpan(text: _studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '. Redirection en cours...'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
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
    } catch (_) {
      // Comme Vue : passer à l'étape 2 même si send échoue silencieusement côté UI
    }
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
