import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import 'widgets/auth_shared.dart';

// Définition locale des couleurs officielles du logo ISCAE
class IscaeColors {
  static const Color green = Color(0xFF0B8243); // Vert texte/flèche
  static const Color cyanDark = Color(0xFF4A7479); // Bleu-gris de la sphère
  static const Color cyanLight = Color(0xFF79C2C4); // Bleu-cyan clair de la sphère
  static const Color white = Color(0xFFFFFFFF);

  // Dégradé inspiré de la sphère pour les arrière-plans mobiles
  static const LinearGradient brandGradient = LinearGradient(
    colors: [cyanDark, cyanLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

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
      // Changé à true pour permettre l'adaptation de l'espace de dessin avec le clavier
      resizeToAvoidBottomInset: true,
      body: Row(
        children: [
          if (wide) const Expanded(flex: 5, child: AuthBrandingPanel()),
          Expanded(
            flex: wide ? 7 : 1,
            child: Container(
              decoration: BoxDecoration(
                // Application du dégradé ISCAE sur mobile
                gradient: wide ? null : IscaeColors.brandGradient,
                color: wide ? Theme.of(context).scaffoldBackgroundColor : null,
              ),
              child: SafeArea(
                child: Center(
                  // SOLUTION ANTI-OVERFLOW : On enveloppe dans un scroll pour absorber les bannières d'erreurs et le clavier
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: wide ? 32 : 12),
                    child: AuthFormCard(
                      // Padding interne de la Card ajusté
                      padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 20, vertical: wide ? 40 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Ajustement strict au contenu
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!wide) ...[
                            const Center(child: AuthLogoCircle(size: 64, imageSize: 56, onLightBackground: true)),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'ISCAE Réclamations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: IscaeColors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _step == _LoginStep.login
                                ? _buildLoginForm(wide)
                                : _buildDeviceOtpForm(wide),
                          ),
                          const SizedBox(height: 16),
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

  Widget _buildFormHeader({required IconData icon, required String title, required String subtitle, bool warning = false, required bool wide}) {
    return Column(
      key: ValueKey(title),
      children: [
        Container(
          width: wide ? 64 : 52,
          height: wide ? 64 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: warning
                  ? const [Color(0xFFE65100), Color(0xFFFF9800)]
                  : const [IscaeColors.cyanDark, IscaeColors.cyanLight],
            ),
            boxShadow: [
              BoxShadow(
                color: (warning ? const Color(0xFFE65100) : IscaeColors.cyanDark).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: wide ? 28 : 22),
        ),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: wide ? 22 : 19, fontWeight: FontWeight.w800, color: AuthColors.title)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AuthColors.muted)),
      ],
    );
  }

  Widget _buildLoginForm(bool wide) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormHeader(
          icon: Icons.shield_outlined,
          title: 'Bienvenue',
          subtitle: 'Connectez-vous à votre espace',
          wide: wide,
        ),
        SizedBox(height: wide ? 32 : 16),
        const AuthFieldLabel('Matricule ou Email'),
        AuthTextField(
          controller: _loginController,
          hint: 'Entrez votre matricule ou email',
          prefixIcon: Icons.person_outline,
          enabled: !_loading,
        ),
        SizedBox(height: wide ? 16 : 10),
        const AuthFieldLabel('Mot de passe'),
        AuthTextField(
          controller: _passwordController,
          hint: 'Entrez votre mot de passe',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          suffix: IconButton(
            icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
            onPressed: () => setState(() => _showPwd = !_showPwd),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 32,
            child: TextButton.icon(
              onPressed: _loading ? null : () => Navigator.pushNamed(context, '/forgot-password'),
              icon: const Icon(Icons.help_outline, size: 13, color: IscaeColors.green),
              label: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: IscaeColors.green),
              ),
            ),
          ),
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 4),
          AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
          const SizedBox(height: 12),
        ],
        Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: IscaeColors.green),
            ),
          ),
          child: AuthPrimaryButton(
            label: 'Se connecter',
            icon: Icons.login,
            loading: _loading,
            onPressed: _handleLogin,
          ),
        ),
        SizedBox(height: wide ? 20 : 12),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('ou', style: TextStyle(color: AuthColors.muted, fontSize: 12)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        SizedBox(height: wide ? 20 : 12),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              const Text('Pas encore de compte ? ', style: TextStyle(color: AuthColors.muted, fontSize: 12)),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: _loading ? null : () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  'Créer mon compte',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: IscaeColors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceOtpForm(bool wide) {
    return Column(
      key: const ValueKey('otp_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormHeader(
          icon: Icons.devices,
          title: 'Nouvel appareil',
          subtitle: 'Code envoyé à $_maskedEmail',
          warning: true,
          wide: wide,
        ),
        SizedBox(height: wide ? 24 : 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange.shade800, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nouvel appareil détecté. Vérifiez votre identité.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: wide ? 24 : 14),
        const AuthFieldLabel('Code à 6 chiffres'),
        OtpInputRow(
          key: _otpKey,
          enabled: !_loading,
          onChanged: (_) => setState(() => _errorMsg = ''),
        ),
        SizedBox(height: wide ? 20 : 12),
        Center(
          child: resendCooldown > 0
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AuthColors.formBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AuthColors.fieldBorder),
            ),
            child: Text('Renvoyer dans ${resendCooldown}s', style: const TextStyle(fontSize: 11, color: AuthColors.muted)),
          )
              : TextButton.icon(
            onPressed: _loading ? null : _handleResendOtp,
            icon: const Icon(Icons.refresh, size: 14, color: IscaeColors.green),
            label: const Text('Renvoyer le code', style: TextStyle(fontSize: 12, color: IscaeColors.green)),
          ),
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 12),
          AuthErrorBanner(message: _errorMsg, onClose: () => setState(() => _errorMsg = '')),
        ],
        SizedBox(height: wide ? 20 : 12),
        Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: IscaeColors.green),
            ),
          ),
          child: AuthPrimaryButton(
            label: 'Vérifier et continuer',
            icon: Icons.verified_user_outlined,
            loading: _loading,
            onPressed: _handleVerifyDeviceOtp,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: TextButton.icon(
            onPressed: _loading
                ? null
                : () => setState(() {
              _step = _LoginStep.login;
              _errorMsg = '';
              _otpKey.currentState?.clear();
            }),
            icon: const Icon(Icons.arrow_back, size: 14, color: AuthColors.muted),
            label: const Text('Retour à la connexion', style: TextStyle(fontSize: 12, color: AuthColors.muted)),
          ),
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