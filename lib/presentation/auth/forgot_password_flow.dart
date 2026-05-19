import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import 'widgets/auth_shared.dart';

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> with ResendCooldownMixin {
  int _step = 1;
  bool _loading = false;
  bool _showPwd = false;
  String _errorMsg = '';
  String _errorType = 'error';

  int? _userId;
  String? _resetToken;
  String _maskedEmail = '';

  final _emailController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputRowState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const _stepLabels = ['Email', 'Vérification', 'Nouveau MDP'];

  int get _stepPercent {
    if (_step == 1) return 10;
    if (_step == 2) return 45;
    if (_step == 3) return 80;
    return 100;
  }

  Color get _stepColor {
    const colors = [Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF10B981)];
    if (_step <= 0 || _step > colors.length) return colors[0];
    return colors[_step - 1];
  }

  List<({String text, bool met})> get _passwordRules {
    final p = _passwordController.text;
    return [
      (text: '8 caractères', met: p.length >= 8),
      (text: 'Majuscule', met: RegExp(r'[A-Z]').hasMatch(p)),
      (text: 'Chiffre', met: RegExp(r'[0-9]').hasMatch(p)),
      (text: 'Symbole', met: RegExp(r'[^A-Za-z0-9]').hasMatch(p)),
    ];
  }

  int get _strengthScore => _passwordRules.where((r) => r.met).length;

  String get _strengthLabel => ['', 'Faible', 'Moyen', 'Bon', 'Fort'][_strengthScore];

  Color get _strengthColor {
    const map = {1: Color(0xFFEF4444), 2: Color(0xFFF59E0B), 3: Color(0xFF3B82F6), 4: Color(0xFF10B981)};
    return map[_strengthScore] ?? const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            Expanded(
              flex: 5,
              child: AuthForgotBrandingPanel(
                currentStep: _step > 3 ? 3 : _step,
                onBackToLogin: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
            ),
          Expanded(
            flex: wide ? 7 : 1,
            child: Container(
              color: AuthColors.forgotBg,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 32 : 16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 490),
                      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20, vertical: wide ? 44 : 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!wide) ...[
                            Center(child: AuthLogoCircle(size: 66, imageSize: 54)),
                            const SizedBox(height: 20),
                          ],
                          if (_step < 4) _buildProgressBar(),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: _buildStepContent(),
                          ),
                          if (_step < 4) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                icon: const Icon(Icons.arrow_back, size: 14),
                                label: const Text('Retour à la connexion', style: TextStyle(color: Color(0xFF6366F1))),
                              ),
                            ),
                          ],
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

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ÉTAPE ${_step > 3 ? 3 : _step} SUR 3',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1),
            ),
            Text('$_stepPercent%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _stepColor)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _stepPercent / 100,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            color: _stepColor,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(3, (i) {
            final stepNum = i + 1;
            final done = _step > stepNum;
            final current = _step == stepNum;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || current ? (done ? const Color(0xFF4338CA) : const Color(0xFF6366F1)) : const Color(0xFFE2E8F0),
                      boxShadow: current ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.2), spreadRadius: 2)] : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text('$stepNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: current ? Colors.white : const Color(0xFF94A3B8))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepLabels[i],
                    style: TextStyle(fontSize: 10, fontWeight: current || done ? FontWeight.w600 : FontWeight.w500, color: current || done ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
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

  Widget _buildStepHeader({required IconData icon, required Color iconColor, required Color iconBg, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: AuthColors.muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF6366F1),
          iconBg: const Color(0x1A6366F1),
          title: 'Mot de passe oublié ?',
          subtitle: 'Entrez l\'email associé à votre compte ISCAE',
        ),
        const SizedBox(height: 24),
        const AuthFieldLabel('Adresse email'),
        AuthTextField(
          controller: _emailController,
          hint: 'votre.email@exemple.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: !_loading,
        ),
        const SizedBox(height: 8),
        Text(
          'Un code à 6 chiffres sera envoyé à votre adresse email.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAlert(),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Envoyer le code de vérification',
          icon: Icons.send_outlined,
          loading: _loading,
          onPressed: _handleSendOtp,
          gradient: const [Color(0xFF4338CA), Color(0xFF4338CA)],
        ),
      ],
    );
  }

  Widget _buildStep2({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.vpn_key_outlined,
          iconColor: const Color(0xFFF59E0B),
          iconBg: const Color(0x1AF59E0B),
          title: 'Code de vérification',
          subtitle: 'Code envoyé à $_maskedEmail',
        ),
        const SizedBox(height: 24),
        const AuthFieldLabel('Code OTP (6 chiffres)'),
        OtpInputRow(key: _otpKey, enabled: !_loading, onChanged: (_) => setState(() => _errorMsg = '')),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Valide 10 minutes', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (resendCooldown > 0)
              Text('Renvoyer dans ${resendCooldown}s', style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold))
            else
              TextButton(
                onPressed: _loading ? null : _handleSendOtp,
                child: const Text('Renvoyer'),
              ),
          ],
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAlert(),
        ],
        const SizedBox(height: 20),
        AuthPrimaryButton(
          label: 'Vérifier le code',
          icon: Icons.check_circle_outline,
          loading: _loading,
          onPressed: _handleVerifyOtp,
          gradient: const [Color(0xFF4338CA), Color(0xFF4338CA)],
        ),
        TextButton.icon(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _step = 1;
                    _errorMsg = '';
                  }),
          icon: const Icon(Icons.arrow_back, size: 14),
          label: const Text('Changer l\'adresse email'),
        ),
      ],
    );
  }

  Widget _buildStep3({Key? key}) {
    final canSubmit = _passwordController.text == _confirmPasswordController.text && _passwordController.text.length >= 8;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.lock_reset,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0x1A10B981),
          title: 'Nouveau mot de passe',
          subtitle: 'Choisissez un mot de passe sécurisé',
        ),
        const SizedBox(height: 24),
        const AuthFieldLabel('Nouveau mot de passe'),
        AuthTextField(
          controller: _passwordController,
          hint: 'Minimum 8 caractères',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          onChanged: (_) => setState(() {}),
          suffix: IconButton(
            icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPwd = !_showPwd),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Force du mot de passe', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(_strengthLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _strengthColor)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: _strengthScore >= i + 1 ? _strengthColor : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _passwordRules.map((r) {
                  return Chip(
                    label: Text(r.text, style: const TextStyle(fontSize: 11)),
                    avatar: Icon(r.met ? Icons.check : Icons.close, size: 14, color: r.met ? Colors.green : Colors.grey),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: r.met ? Colors.green.shade50 : Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Confirmer le mot de passe'),
        AuthTextField(
          controller: _confirmPasswordController,
          hint: 'Répétez le mot de passe',
          prefixIcon: Icons.lock_outline,
          obscure: !_showPwd,
          enabled: !_loading,
          onChanged: (_) => setState(() {}),
        ),
        if (_confirmPasswordController.text.isNotEmpty && _passwordController.text != _confirmPasswordController.text)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Les mots de passe ne correspondent pas.', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAlert(),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Réinitialiser le mot de passe',
          icon: Icons.lock_reset,
          loading: _loading,
          onPressed: canSubmit ? _handleResetPassword : null,
          gradient: const [Color(0xFF4338CA), Color(0xFF4338CA)],
        ),
      ],
    );
  }

  Widget _buildSuccess({Key? key}) {
    return Column(
      key: key,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.shade50),
          child: const Icon(Icons.check_circle, size: 56, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 24),
        const Text('Mot de passe réinitialisé !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Votre mot de passe a été mis à jour avec succès.\nVous pouvez maintenant vous connecter.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          label: 'Se connecter',
          icon: Icons.login,
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ],
    );
  }

  Widget _buildAlert() {
    final isWarning = _errorType == 'warning';
    final color = isWarning ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(isWarning ? Icons.warning_amber_outlined : Icons.error_outline, color: color.shade800, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMsg, style: TextStyle(fontSize: 13, color: color.shade900))),
          InkWell(onTap: () => setState(() => _errorMsg = ''), child: Icon(Icons.close, size: 16, color: color.shade400)),
        ],
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _errorMsg = '';
      _errorType = 'error';
    });
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Veuillez entrer votre adresse email.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _errorMsg = 'Veuillez entrer une adresse email valide.');
      return;
    }

    setState(() => _loading = true);
    final result = await ApiConfig().authService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result is Map && result['success'] == true) {
      final data = dataFromApiResult(result);
      setState(() {
        _userId = data?['user_id'] != null ? int.tryParse(data!['user_id'].toString()) : null;
        _maskedEmail = (data?['masked_email'] ?? email).toString();
        if (_step == 1) _step = 2;
      });
      startCooldown();
      return;
    }

    if (result is Map) {
      final code = result['error_code']?.toString();
      if (code == 'EMAIL_NOT_FOUND') {
        setState(() {
          _errorType = 'warning';
          _errorMsg = "Aucun étudiant trouvé avec cet email. Contactez l'administration.";
        });
        return;
      }
    }

    setState(() => _errorMsg = messageFromApiResult(result) ?? 'Une erreur est survenue. Réessayez.');
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpKey.currentState?.value ?? '';
    setState(() => _errorMsg = '');
    if (otp.length < 6) {
      setState(() => _errorMsg = 'Veuillez entrer le code à 6 chiffres.');
      return;
    }
    if (_userId == null) {
      setState(() => _errorMsg = 'Session invalide. Recommencez.');
      return;
    }

    setState(() => _loading = true);
    final result = await ApiConfig().authService.forgotVerifyOtp(_userId!, otp);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result is Map && result['success'] == true) {
      final data = dataFromApiResult(result);
      setState(() {
        _resetToken = (data?['reset_token'] ?? result['reset_token'])?.toString();
        _step = 3;
      });
      return;
    }

    setState(() => _errorMsg = messageFromApiResult(result) ?? 'Code invalide ou expiré.');
    _otpKey.currentState?.clear();
  }

  Future<void> _handleResetPassword() async {
    setState(() => _errorMsg = '');
    if (_passwordController.text.length < 8) {
      setState(() => _errorMsg = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMsg = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (_resetToken == null) {
      setState(() => _errorMsg = 'Session expirée. Recommencez.');
      return;
    }

    setState(() => _loading = true);
    final result = await ApiConfig().authService.resetPassword(
      resetToken: _resetToken!,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result is Map && result['success'] == true) {
      setState(() => _step = 4);
      return;
    }

    setState(() => _errorMsg = messageFromApiResult(result) ?? 'Erreur lors de la réinitialisation.');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
