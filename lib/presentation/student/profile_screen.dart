import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/url_resolver.dart';
import '../../data/models/profile_model.dart';
import 'profile_controller.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Section active : 0 = Informations, 1 = Sécurité ──────────────────────
  int _section = 0;

  // ── Étapes multi-step dans "Informations" ─────────────────────────────────
  int _infoStep = 0; // 0=Identité, 1=Complémentaires, 2=Récapitulatif
  static const _infoStepLabels = ['Identité', 'Complémentaires', 'Récapitulatif'];

  // ── Champs formulaire ──────────────────────────────────────────────────────
  final _prenomController        = TextEditingController();
  final _nomController           = TextEditingController();
  final _emailController         = TextEditingController();
  final _phoneController         = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController   = TextEditingController();
  final _nniController           = TextEditingController();
  final _adresseController       = TextEditingController();

  // ── Champs mot de passe ────────────────────────────────────────────────────
  final _pwdCurrentController = TextEditingController();
  final _pwdNewController     = TextEditingController();
  final _pwdConfirmController = TextEditingController();

  bool _showPwdCurrent = false;
  bool _showPwdNew     = false;
  bool _showPwdConfirm = false;

  // ── Photo ──────────────────────────────────────────────────────────────────
  bool      _formPopulated  = false;
  Uint8List? _previewBytes;
  int        _photoCacheBust = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pwdNewController.addListener(() => setState(() {}));
    _pwdConfirmController.addListener(() => setState(() {}));
    Future.microtask(() => context.read<ProfileController>().loadProfile());
  }

  @override
  void dispose() {
    for (final c in [
      _prenomController, _nomController, _emailController, _phoneController,
      _dateNaissanceController, _lieuNaissanceController, _nationaliteController,
      _nniController, _adresseController,
      _pwdCurrentController, _pwdNewController, _pwdConfirmController,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _populateForm(ProfileModel p) {
    if (_formPopulated) return;
    _prenomController.text        = p.prenom ?? '';
    _nomController.text           = p.nom ?? '';
    _emailController.text         = p.email;
    _phoneController.text         = p.phone ?? '';
    _dateNaissanceController.text = _dateVal(p.dateNaissance);
    _lieuNaissanceController.text = p.lieuNaissance ?? '';
    _nationaliteController.text   = p.nationalite ?? '';
    _nniController.text           = p.nni ?? '';
    _adresseController.text       = p.adresse ?? '';
    _formPopulated = true;
  }

  String _dateVal(String? raw) =>
      (raw != null && raw.length >= 10) ? raw.substring(0, 10) : (raw ?? '');

  String _initials(ProfileModel p) {
    final name = p.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  Color _avatarColor(ProfileModel p) {
    const colors = [Color(0xFF00695C), Color(0xFF2E7D32), Color(0xFF00838F), Color(0xFF1565C0), Color(0xFF3949AB)];
    final name = p.fullName;
    return name.isEmpty ? colors.first : colors[name.codeUnitAt(0) % colors.length];
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const m = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) { return raw; }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}'
          ' ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return raw; }
  }

  void _notify(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickPhoto(ProfileController ctrl, ProfileModel p) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowMultiple: false, withData: true,
      allowedExtensions: const ['jpg','jpeg','png','webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null && !kIsWeb) bytes = await File(picked.path!).readAsBytes();
    if (bytes == null) { _notify('Impossible de lire l\'image.', isError: true); return; }
    if (bytes.length > 3 * 1024 * 1024) { _notify('Fichier trop lourd (max 3 Mo).', isError: true); return; }
    setState(() => _previewBytes = bytes);
    final ok = await ctrl.updatePhoto(path: picked.path, bytes: bytes, fileName: picked.name);
    if (!mounted) return;
    if (ok) {
      setState(() { _previewBytes = null; _formPopulated = false; _photoCacheBust++; });
      _notify('Photo de profil mise à jour.');
    } else {
      setState(() => _previewBytes = null);
      _notify(ctrl.errorMessage ?? 'Erreur lors de l\'upload.', isError: true);
    }
  }

  Future<void> _saveProfile(ProfileController ctrl) async {
    final ok = await ctrl.updateProfile(
      prenom: _prenomController.text.trim(), nom: _nomController.text.trim(),
      email: _emailController.text.trim(), phone: _phoneController.text.trim(),
      dateNaissance: _dateNaissanceController.text.trim(), lieuNaissance: _lieuNaissanceController.text.trim(),
      nationalite: _nationaliteController.text.trim(), adresse: _adresseController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _formPopulated = false;
      if (ctrl.profile != null) _populateForm(ctrl.profile!);
      _notify('Profil mis à jour avec succès.');
    } else {
      _notify(ctrl.errorMessage ?? 'Erreur lors de la mise à jour.', isError: true);
    }
  }

  Future<void> _savePassword(ProfileController ctrl) async {
    if (!_canSavePwd) return;
    final ok = await ctrl.updatePassword(
      currentPassword: _pwdCurrentController.text,
      password: _pwdNewController.text,
      passwordConfirmation: _pwdConfirmController.text,
    );
    if (!mounted) return;
    if (ok) {
      _pwdCurrentController.clear(); _pwdNewController.clear(); _pwdConfirmController.clear();
      _notify('Mot de passe modifié avec succès.');
    } else {
      _notify(ctrl.errorMessage ?? 'Erreur lors du changement.', isError: true);
    }
  }

  bool get _canSavePwd {
    final p = _pwdNewController.text;
    return _pwdCurrentController.text.isNotEmpty && p.length >= 8 && p == _pwdConfirmController.text;
  }

  List<({String label, bool ok})> get _pwdCriteria => [
    (label: 'Au moins 8 caractères',       ok: _pwdNewController.text.length >= 8),
    (label: 'Une lettre majuscule',         ok: RegExp(r'[A-Z]').hasMatch(_pwdNewController.text)),
    (label: 'Un chiffre',                   ok: RegExp(r'[0-9]').hasMatch(_pwdNewController.text)),
    (label: 'Un caractère spécial (!@#…)', ok: RegExp(r'[^a-zA-Z0-9]').hasMatch(_pwdNewController.text)),
  ];

  ({int score, Color color, String label}) get _pwdStrength {
    final score = _pwdCriteria.where((c) => c.ok).length;
    const levels = [
      (score: 1, color: Color(0xFFEF4444), label: 'Très faible'),
      (score: 2, color: Color(0xFFF97316), label: 'Faible'),
      (score: 3, color: Color(0xFFEAB308), label: 'Moyen'),
      (score: 4, color: Color(0xFF22C55E), label: 'Fort'),
    ];
    if (score == 0 || _pwdNewController.text.isEmpty) return (score: 0, color: Colors.grey.shade300, label: '');
    return levels[score - 1];
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ctrl    = context.watch<ProfileController>();
    final primary = Theme.of(context).colorScheme.primary;

    if (ctrl.isLoading && ctrl.profile == null) return const Center(child: CircularProgressIndicator());

    if (ctrl.hasError && ctrl.profile == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(ctrl.errorMessage ?? 'Impossible de charger le profil.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => ctrl.loadProfile(), icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
        ]),
      ));
    }

    final profile = ctrl.profile;
    if (profile == null) return const Center(child: Text('Aucune donnée disponible'));
    _populateForm(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sous-titre ─────────────────────────────────────────────────────
          Text('Gérez vos informations personnelles et votre sécurité',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),

          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final left  = _buildLeftColumn(profile, ctrl, primary);
            final right = _buildRightColumn(profile, ctrl, primary);
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 290, child: left),
                const SizedBox(width: 20),
                Expanded(child: right),
              ]);
            }
            return Column(children: [left, const SizedBox(height: 16), right]);
          }),
        ],
      ),
    );
  }

  // ── COLONNE GAUCHE ─────────────────────────────────────────────────────────

  Widget _buildLeftColumn(ProfileModel p, ProfileController ctrl, Color primary) {
    return Column(children: [
      _buildIdentityCard(p, ctrl, primary),
      const SizedBox(height: 12),
      _buildSecurityCard(p, primary),
    ]);
  }

  Widget _buildIdentityCard(ProfileModel p, ProfileController ctrl, Color primary) {
    final stats = ctrl.recStats;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.appBorder)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar
          Stack(clipBehavior: Clip.none, children: [
            ProfileAvatar(
              radius: 46, initials: _initials(p), backgroundColor: _avatarColor(p),
              photoUrl: p.photoUrl, photoPath: p.photoPath,
              localBytes: _previewBytes, cacheBust: _photoCacheBust,
            ),
            Positioned(bottom: 0, right: 0, child: Material(
              color: primary, shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: ctrl.uploadingPhoto ? null : () => _pickPhoto(ctrl, p),
                child: SizedBox(width: 30, height: 30, child: ctrl.uploadingPhoto
                    ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 15)),
              ),
            )),
          ]),
          const SizedBox(height: 14),

          Text(
            p.fullName.isNotEmpty ? p.fullName : p.email,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: context.appSurfaceLow, borderRadius: BorderRadius.circular(6)),
            child: Text(p.matricule ?? '—', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: context.appMuted)),
          ),
          const SizedBox(height: 10),

          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            Chip(
              label: Text(p.niveau?.label ?? 'N/A', style: const TextStyle(fontSize: 10)),
              backgroundColor: primary, labelStyle: const TextStyle(color: Colors.white),
              visualDensity: VisualDensity.compact, padding: EdgeInsets.zero,
            ),
            Chip(label: Text(p.academicYear ?? '—', style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
          ]),
          const Divider(height: 28),

          _infoRow(Icons.email_outlined,      p.email,                            primary),
          _infoRow(Icons.phone_outlined,       p.phone ?? '—',                    primary),
          _infoRow(Icons.domain_outlined,      p.filiere?.name ?? '—',            primary),
          _infoRow(Icons.location_on_outlined, p.adresse ?? '—',                  primary),
          _infoRow(Icons.cake_outlined,        _formatDate(p.dateNaissance),      primary),
          const Divider(height: 28),

          Row(children: [
            _statItem('${stats.total}',    'Total',      primary),
            Container(width: 1, height: 28, color: Colors.grey.shade300),
            _statItem('${stats.pending}',  'En attente', Colors.orange),
            Container(width: 1, height: 28, color: Colors.grey.shade300),
            _statItem('${stats.resolved}', 'Résolues',   Colors.green),
          ]),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value, Color primary) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: primary),
      const SizedBox(width: 7),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
    ]),
  );

  Widget _statItem(String num, String label, Color color) => Expanded(
    child: Column(children: [
      FittedBox(fit: BoxFit.scaleDown, child: Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color))),
      const SizedBox(height: 3),
      Text(label.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, color: Colors.grey[600], letterSpacing: 0.3)),
    ]),
  );

  Widget _buildSecurityCard(ProfileModel p, Color primary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.shield, size: 16, color: primary),
            const SizedBox(width: 7),
            Text('Sécurité du compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primary)),
          ]),
          const SizedBox(height: 10),
          _secRow(Icons.check_circle, Colors.green, 'Email vérifié'),
          const SizedBox(height: 7),
          _secRow(
            p.passwordChangedAt != null ? Icons.check_circle : Icons.warning_amber,
            p.passwordChangedAt != null ? Colors.green : Colors.orange,
            p.passwordChangedAt != null
                ? 'Mot de passe · modifié le ${_formatDate(p.passwordChangedAt)}'
                : 'Mot de passe · jamais modifié',
          ),
          if (p.lastLoginAt != null) ...[
            const SizedBox(height: 7),
            _secRow(Icons.login, Colors.blue, 'Dernière connexion : ${_formatDateTime(p.lastLoginAt)}'),
          ],
        ]),
      ),
    );
  }

  Widget _secRow(IconData icon, Color color, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700]))),
    ],
  );

  // ── COLONNE DROITE ─────────────────────────────────────────────────────────

  Widget _buildRightColumn(ProfileModel p, ProfileController ctrl, Color primary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // ── Deux boutons haut ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(child: _sectionBtn(
              label: 'Informations',
              icon: Icons.edit_outlined,
              index: 0,
              primary: primary,
            )),
            const SizedBox(width: 10),
            Expanded(child: _sectionBtn(
              label: 'Sécurité',
              icon: Icons.lock_outline,
              index: 1,
              primary: primary,
            )),
          ]),
        ),

        const SizedBox(height: 4),
        Divider(height: 1, color: context.appBorder),

        // ── Contenu selon section ───────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _section == 0
              ? _buildInfoSection(p, ctrl, primary)
              : _buildSecuritySection(ctrl, primary),
        ),
      ]),
    );
  }

  Widget _sectionBtn({required String label, required IconData icon, required int index, required Color primary}) {
    final active = _section == index;
    return GestureDetector(
      onTap: () => setState(() => _section = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? primary : context.appBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: active ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey[700])),
        ]),
      ),
    );
  }

  // ── SECTION INFORMATIONS (multi-étapes) ────────────────────────────────────

  Widget _buildInfoSection(ProfileModel p, ProfileController ctrl, Color primary) {
    return Padding(
      key: const ValueKey('info'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // Stepper
          _buildStepper(primary),
          const SizedBox(height: 24),

          // Contenu de l'étape
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _buildInfoStepContent(p, primary),
          ),
          const SizedBox(height: 24),

          // Navigation
          Row(children: [
            if (_infoStep > 0)
              OutlinedButton.icon(
                onPressed: () => setState(() => _infoStep--),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Précédent', style: TextStyle(fontSize: 12)),
              ),
            const Spacer(),
            if (_infoStep < 2)
              FilledButton.icon(
                onPressed: () => setState(() => _infoStep++),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Suivant', style: TextStyle(fontSize: 12)),
              )
            else
              FilledButton.icon(
                onPressed: ctrl.isUpdating ? null : () => _saveProfile(ctrl),
                icon: ctrl.isUpdating
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 14),
                label: const Text('Enregistrer', style: TextStyle(fontSize: 12)),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStepper(Color primary) {
    return Row(
      children: List.generate(_infoStepLabels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = _infoStep > i ~/ 2;
          return Expanded(child: Container(
            height: 2, margin: const EdgeInsets.only(bottom: 18),
            color: done ? primary : Colors.grey.shade300,
          ));
        }
        final idx    = i ~/ 2;
        final active = _infoStep == idx;
        final done   = _infoStep > idx;
        return Column(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? primary : Colors.grey.shade200,
              boxShadow: active ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8)] : null,
            ),
            child: Center(child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('${idx + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.grey))),
          ),
          const SizedBox(height: 4),
          Text(
            _infoStepLabels[idx],
            style: TextStyle(
              fontSize: 10,
              fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
              color: active || done ? primary : Colors.grey,
            ),
          ),
        ]);
      }),
    );
  }

  Widget _buildInfoStepContent(ProfileModel p, Color primary) {
    switch (_infoStep) {
      case 0: return _buildStep0(primary);
      case 1: return _buildStep1(primary);
      default: return _buildStep2(p, primary);
    }
  }

  // Étape 0 — Identité
  Widget _buildStep0(Color primary) {
    return Column(key: const ValueKey(0), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionLabel('Identité & Contact', Icons.person_outline, primary),
      LayoutBuilder(builder: (context, c) {
        final two = c.maxWidth > 480;
        final fields = [
          _field(_prenomController,  'Prénom',        Icons.person_outline),
          _field(_nomController,     'Nom',            Icons.person_outline),
          _field(_emailController,   'Email',          Icons.email_outlined, type: TextInputType.emailAddress),
          _field(_phoneController,   'Téléphone',      Icons.phone_outlined,  type: TextInputType.phone),
        ];
        if (!two) return Column(children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 14), child: f)).toList());
        return Column(children: [
          Row(children: [Expanded(child: fields[0]), const SizedBox(width: 14), Expanded(child: fields[1])]),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: fields[2]), const SizedBox(width: 14), Expanded(child: fields[3])]),
        ]);
      }),
    ]);
  }

  // Étape 1 — Complémentaires
  Widget _buildStep1(Color primary) {
    return Column(key: const ValueKey(1), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionLabel('Informations complémentaires', Icons.info_outline, primary),
      LayoutBuilder(builder: (context, c) {
        final two = c.maxWidth > 480;
        final w1 = _dateField();
        final w2 = _field(_lieuNaissanceController, 'Lieu de naissance', Icons.place_outlined);
        final w3 = _field(_nationaliteController,   'Nationalité',       Icons.flag_outlined);
        final w4 = _field(_nniController,           'NNI',               Icons.badge_outlined, readOnly: true);
        final w5 = _field(_adresseController,       'Adresse complète',  Icons.home_outlined);
        if (!two) return Column(children: [w1, w2, w3, w4, w5].map((f) => Padding(padding: const EdgeInsets.only(bottom: 14), child: f)).toList());
        return Column(children: [
          Row(children: [Expanded(child: w1), const SizedBox(width: 14), Expanded(child: w2)]),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: w3), const SizedBox(width: 14), Expanded(child: w4)]),
          const SizedBox(height: 14),
          w5,
        ]);
      }),
    ]);
  }

  // Étape 2 — Récapitulatif + académique
  Widget _buildStep2(ProfileModel p, Color primary) {
    return Column(key: const ValueKey(2), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionLabel('Récapitulatif', Icons.preview_outlined, primary),

      // Résumé
      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vérifiez avant d\'enregistrer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
          const SizedBox(height: 10),
          _summaryRow('Prénom',    _prenomController.text),
          _summaryRow('Nom',       _nomController.text),
          _summaryRow('Email',     _emailController.text),
          _summaryRow('Téléphone', _phoneController.text),
          _summaryRow('Lieu naiss.', _lieuNaissanceController.text),
          _summaryRow('Adresse',   _adresseController.text),
        ]),
      ),

      _buildReadonlyBlock(p),
    ]);
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600))),
      const SizedBox(width: 8),
      Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _sectionLabel(String title, IconData icon, Color primary) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Icon(icon, size: 14, color: primary),
      const SizedBox(width: 6),
      Expanded(child: Text(
        title.toUpperCase(),
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey[600]),
      )),
    ]),
  );

  Widget _dateField() {
    return TextFormField(
      controller: _dateNaissanceController, readOnly: true,
      decoration: const InputDecoration(labelText: 'Date de naissance', prefixIcon: Icon(Icons.cake_outlined), border: OutlineInputBorder()),
      onTap: () async {
        final init = DateTime.tryParse(_dateNaissanceController.text) ?? DateTime(2000);
        final picked = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(1950), lastDate: DateTime.now(), locale: const Locale('fr'));
        if (picked != null) {
          _dateNaissanceController.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
        }
      },
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? type, bool readOnly = false}) {
    return TextFormField(
      controller: ctrl, readOnly: readOnly, keyboardType: type,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder(),
        filled: readOnly, fillColor: readOnly ? context.appSurfaceLow : null,
        helperText: readOnly ? 'Non modifiable' : null,
      ),
    );
  }

  Widget _buildReadonlyBlock(ProfileModel p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline, size: 13, color: context.appMuted),
          const SizedBox(width: 6),
          Expanded(child: Text('INFORMATIONS ACADÉMIQUES (NON MODIFIABLES)', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.appMuted))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 10, children: [
          _readonlyItem('Matricule',        p.matricule ?? '—', mono: true),
          _readonlyItem('Filière',          p.filiere?.name ?? '—'),
          _readonlyItem('Niveau',           p.niveau?.label ?? '—'),
          _readonlyItem('Année académique', p.academicYear ?? '—'),
        ]),
      ]),
    );
  }

  Widget _readonlyItem(String key, String value, {bool mono = false}) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 110, maxWidth: 190),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(key.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[600])),
      const SizedBox(height: 3),
      Text(value, maxLines: 3, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null)),
    ]),
  );

  // ── SECTION SÉCURITÉ ───────────────────────────────────────────────────────

  Widget _buildSecuritySection(ProfileController ctrl, Color primary) {
    final strength   = _pwdStrength;
    final pwdMatch   = _pwdConfirmController.text.isNotEmpty && _pwdNewController.text == _pwdConfirmController.text;
    final pwdMismatch = _pwdConfirmController.text.isNotEmpty && !pwdMatch;

    return Padding(
      key: const ValueKey('security'),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        _sectionLabel('Changer le mot de passe', Icons.lock, primary),

        // Mot de passe actuel
        _pwdField(_pwdCurrentController, 'Mot de passe actuel', _showPwdCurrent, () => setState(() => _showPwdCurrent = !_showPwdCurrent)),
        const SizedBox(height: 14),

        // Séparateur
        Row(children: [
          const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('Nouveau mot de passe', style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 14),

        // Nouveau mot de passe
        _pwdField(_pwdNewController, 'Nouveau mot de passe', _showPwdNew, () => setState(() => _showPwdNew = !_showPwdNew)),

        // Indicateur force
        if (_pwdNewController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: List.generate(4, (i) => Expanded(child: Container(
            height: 4, margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < strength.score ? strength.color : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          )))),
          if (strength.label.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 5),
                child: Text(strength.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: strength.color))),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 5, children: _pwdCriteria.map((c) => Row(
            mainAxisSize: MainAxisSize.min, children: [
            Icon(c.ok ? Icons.check_circle : Icons.circle_outlined, size: 11, color: c.ok ? Colors.green : Colors.grey),
            const SizedBox(width: 4),
            Text(c.label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ],
          )).toList()),
        ],
        const SizedBox(height: 14),

        // Confirmer
        _pwdField(
          _pwdConfirmController, 'Confirmer le nouveau mot de passe',
          _showPwdConfirm, () => setState(() => _showPwdConfirm = !_showPwdConfirm),
          errorText:  pwdMismatch ? 'Les mots de passe ne correspondent pas' : null,
          helperText: pwdMatch    ? 'Mots de passe identiques ✓' : null,
        ),
        const SizedBox(height: 14),

        // Conseil
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Row(children: [
            Icon(Icons.shield_outlined, color: primary, size: 17),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Utilisez au moins 8 caractères avec majuscules, chiffres et symboles.',
              style: TextStyle(fontSize: 11, color: context.appOnSurface),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: (!_canSavePwd || ctrl.isUpdating) ? null : () => _savePassword(ctrl),
            icon: ctrl.isUpdating
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock, size: 14),
            label: const Text('Changer le mot de passe', style: TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _pwdField(TextEditingController ctrl, String label, bool visible, VoidCallback onToggle, {String? errorText, String? helperText}) {
    return TextFormField(
      controller: ctrl, obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility_off : Icons.visibility), onPressed: onToggle),
        border: const OutlineInputBorder(),
        errorText: errorText, helperText: helperText,
        helperStyle: helperText != null ? const TextStyle(color: Colors.green) : null,
      ),
    );
  }
}