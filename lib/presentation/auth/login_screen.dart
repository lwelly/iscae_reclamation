import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import 'widgets/auth_shared.dart';

enum _LoginStep { login, deviceOtp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ResendCooldownMixin {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputRowState>();

  _LoginStep _step = _LoginStep.login;
  bool _loading = false;
  bool _showPwd = false;
  String _errorMsg = '';

  int? _pendingUserId;
  String _maskedEmail = '';

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      body: Row(
        children: [
          if (wide) const Expanded(flex: 5, child: AuthBrandingPanel()),
          Expanded(
            flex: wide ? 7 : 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: wide ? null : AuthColors.brandGradient,
                color: wide ? Theme.of(context).scaffoldBackgroundColor : null,
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 20, vertical: wide ? 32 : 40),
                    child: AuthFormCard(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 24, vertical: wide ? 40 : 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!wide) ...[
                            const Center(child: AuthLogoCircle(size: 72, imageSize: 64, onLightBackground: true)),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'ISCAE Réclamations',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                          if (_step == _LoginStep.login) _buildLoginForm() else _buildDeviceOtpForm(),
                          const SizedBox(height: 24),
                          Text(
                            '© ${DateTime.now().year} ISCAE — Tous droits réservés',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader({required IconData icon, required String title, required String subtitle, bool warning = false}) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: warning
                  ? const [Color(0xFFE65100), Color(0xFFFF9800)]
                  : const [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
            boxShadow: [
              BoxShadow(
                color: (warning ? const Color(0xFFE65100) : const Color(0xFF1A237E)).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AuthColors.title)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AuthColors.muted)),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormHeader(
          icon: Icons.shield_outlined,
          title: 'Bienvenue',
          subtitle: 'Connectez-vous à votre espace',
        ),
        const SizedBox(height: 32),
        const AuthFieldLabel('Matricule ou Email'),
        AuthTextField(
          controller: _loginController,
          hint: 'Entrez votre matricule ou email',
          prefixIcon: Icons.person_outline,
          enabled: !_loading,
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Mot de passe'),
        AuthTextField(
          controller: _passwordController,
          hint: 'Entrez votre mot de passe',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          suffix: IconButton(
            icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
            onPressed: () => setState(() => _showPwd = !_showPwd),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loading ? null : () => Navigator.pushNamed(context, '/forgot-password'),
            icon: const Icon(Icons.help_outline, size: 14),
            label: const Text('Mot de passe oublié ?', style: TextStyle(fontWeight: FontWeight.w600, color: AuthColors.primary)),
          ),
        ),
        if (_errorMsg.isNotEmpty) ...[
          AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
        ],
        AuthPrimaryButton(
          label: 'Se connecter',
          icon: Icons.login,
          loading: _loading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              const Text('Pas encore de compte ? ', style: TextStyle(color: AuthColors.muted, fontSize: 13)),
              TextButton(
                onPressed: _loading ? null : () => Navigator.pushNamed(context, '/register'),
                child: const Text('Créer mon compte', style: TextStyle(fontWeight: FontWeight.w700, color: AuthColors.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormHeader(
          icon: Icons.devices,
          title: 'Nouvel appareil',
          subtitle: 'Code envoyé à $_maskedEmail',
          warning: true,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Connexion depuis un nouvel appareil détectée. Vérifiez votre identité.',
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const AuthFieldLabel('Code à 6 chiffres'),
        OtpInputRow(
          key: _otpKey,
          enabled: !_loading,
          onChanged: (_) => setState(() => _errorMsg = ''),
        ),
        const SizedBox(height: 20),
        Center(
          child: resendCooldown > 0
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AuthColors.formBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AuthColors.fieldBorder),
            ),
            child: Text('Renvoyer dans ${resendCooldown}s', style: const TextStyle(fontSize: 12, color: AuthColors.muted)),
          )
              : TextButton.icon(
            onPressed: _loading ? null : _handleResendOtp,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Renvoyer le code'),
          ),
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 16),
          AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
        ],
        const SizedBox(height: 20),
        AuthPrimaryButton(
          label: 'Vérifier et continuer',
          icon: Icons.verified_user_outlined,
          loading: _loading,
          onPressed: _handleVerifyDeviceOtp,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _loading
              ? null
              : () => setState(() {
            _step = _LoginStep.login;
            _errorMsg = '';
            _otpKey.currentState?.clear();
          }),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Retour à la connexion', style: TextStyle(color: AuthColors.muted)),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMsg = '');
    if (_loginController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMsg = 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiConfig().authService.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
        deviceFingerprint: kDeviceFingerprint,
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

      final requiresOtp = result['requires_device_otp'] == true || result['requiresDeviceOtp'] == true;
      if (requiresOtp) {
        final data = dataFromApiResult(result);
        final userId = data?['user_id'] ?? result['user_id'];
        setState(() {
          _pendingUserId = userId != null ? int.tryParse(userId.toString()) : null;
          _maskedEmail = (data?['masked_email'] ?? result['masked_email'] ?? 'votre email').toString();
          _step = _LoginStep.deviceOtp;
        });
        startCooldown();
        return;
      }

      if (result['success'] == true || result['token'] != null) {
        await _saveTokenAndGoDashboard(result);
        return;
      }

      setState(() => _errorMsg = messageFromApiResult(result) ?? 'Identifiants incorrects. Veuillez réessayer.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Erreur de connexion : $e';
        });
      }
    }
  }

  Future<void> _handleVerifyDeviceOtp() async {
    final otp = _otpKey.currentState?.value ?? '';
    setState(() => _errorMsg = '');
    if (otp.length < 6) {
      setState(() => _errorMsg = 'Veuillez entrer le code à 6 chiffres.');
      return;
    }
    if (_pendingUserId == null) {
      setState(() => _errorMsg = 'Session expirée. Reconnectez-vous.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiConfig().authService.verifyDeviceOtp(
        userId: _pendingUserId!,
        otpCode: otp,
        deviceFingerprint: kDeviceFingerprint,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (result is String) {
        setState(() => _errorMsg = result);
        _otpKey.currentState?.clear();
        return;
      }
      if (result is Map && (result['success'] == true || result['token'] != null)) {
        await _saveTokenAndGoDashboard(result);
        return;
      }
      setState(() => _errorMsg = messageFromApiResult(result) ?? 'Code incorrect ou expiré.');
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

  Future<void> _handleResendOtp() async {
    await _handleLogin();
    if (_step == _LoginStep.deviceOtp) startCooldown();
  }

  Future<void> _saveTokenAndGoDashboard(Map result) async {
    final token = result['token']?.toString();
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      ApiConfig().setAuthToken(token);
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}