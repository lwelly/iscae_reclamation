import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import 'package:provider/provider.dart';

import '../../core/utils/url_resolver.dart';
import '../../data/models/profile_model.dart';
import 'profile_controller.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _nniController = TextEditingController();
  final _adresseController = TextEditingController();

  final _pwdCurrentController = TextEditingController();
  final _pwdNewController = TextEditingController();
  final _pwdConfirmController = TextEditingController();

  bool _showPwdCurrent = false;
  bool _showPwdNew = false;
  bool _showPwdConfirm = false;
  bool _formPopulated = false;
  String? _localPhotoPath;
  Uint8List? _localPhotoBytes;
  int _photoCacheBust = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _pwdNewController.addListener(() => setState(() {}));
    _pwdConfirmController.addListener(() => setState(() {}));
    Future.microtask(() => context.read<ProfileController>().loadProfile());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateNaissanceController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    _nniController.dispose();
    _adresseController.dispose();
    _pwdCurrentController.dispose();
    _pwdNewController.dispose();
    _pwdConfirmController.dispose();
    super.dispose();
  }

  void _populateForm(ProfileModel profile) {
    if (_formPopulated) return;
    _prenomController.text = profile.prenom ?? '';
    _nomController.text = profile.nom ?? '';
    _emailController.text = profile.email;
    _phoneController.text = profile.phone ?? '';
    _dateNaissanceController.text = _dateInputValue(profile.dateNaissance);
    _lieuNaissanceController.text = profile.lieuNaissance ?? '';
    _nationaliteController.text = profile.nationalite ?? '';
    _nniController.text = profile.nni ?? '';
    _adresseController.text = profile.adresse ?? '';
    _formPopulated = true;
  }

  String _dateInputValue(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  String _initials(ProfileModel profile) {
    final name = profile.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  Color _avatarColor(ProfileModel profile) {
    const colors = [
      Color(0xFF00695C),
      Color(0xFF2E7D32),
      Color(0xFF00838F),
      Color(0xFF1565C0),
      Color(0xFF3949AB),
    ];
    final name = profile.fullName;
    if (name.isEmpty) return colors.first;
    return colors[name.codeUnitAt(0) % colors.length];
  }

  void _notify(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPhoto(ProfileController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null && !kIsWeb) {
      bytes = await File(picked.path!).readAsBytes();
    }
    if (bytes == null) {
      _notify(
        kIsWeb
            ? 'Impossible de lire l\'image. Réessayez ou utilisez JPG/PNG.'
            : 'Impossible de lire l\'image sélectionnée.',
        isError: true,
      );
      return;
    }
    if (bytes.length > 3 * 1024 * 1024) {
      _notify('Fichier trop lourd (max 3 Mo).', isError: true);
      return;
    }

    setState(() {
      _localPhotoBytes = bytes;
      _localPhotoPath = kIsWeb ? null : picked.path;
    });

    final ok = await controller.updatePhoto(
      path: picked.path,
      bytes: bytes,
      fileName: picked.name,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _localPhotoBytes = null;
        _localPhotoPath = null;
        _formPopulated = false;
        _photoCacheBust++;
      });
      _notify('Photo de profil mise à jour.');
    } else {
      setState(() {
        _localPhotoBytes = null;
        _localPhotoPath = null;
      });
      _notify(controller.errorMessage ?? 'Erreur lors de l\'upload.', isError: true);
    }
  }

  Future<void> _saveProfile(ProfileController controller) async {
    final ok = await controller.updateProfile(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dateNaissance: _dateNaissanceController.text.trim(),
      lieuNaissance: _lieuNaissanceController.text.trim(),
      nationalite: _nationaliteController.text.trim(),
      adresse: _adresseController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _formPopulated = false;
      if (controller.profile != null) _populateForm(controller.profile!);
      _notify('Profil mis à jour avec succès.');
    } else {
      _notify(controller.errorMessage ?? 'Erreur lors de la mise à jour.', isError: true);
    }
  }

  Future<void> _savePassword(ProfileController controller) async {
    if (!_canSavePwd) return;
    final ok = await controller.updatePassword(
      currentPassword: _pwdCurrentController.text,
      password: _pwdNewController.text,
      passwordConfirmation: _pwdConfirmController.text,
    );
    if (!mounted) return;
    if (ok) {
      _pwdCurrentController.clear();
      _pwdNewController.clear();
      _pwdConfirmController.clear();
      _notify('Mot de passe modifié avec succès.');
    } else {
      _notify(controller.errorMessage ?? 'Erreur lors du changement de mot de passe.', isError: true);
    }
  }

  bool get _canSavePwd {
    final pwd = _pwdNewController.text;
    return _pwdCurrentController.text.isNotEmpty &&
        pwd.length >= 8 &&
        pwd == _pwdConfirmController.text;
  }

  List<({String label, bool ok})> get _pwdCriteria => [
        (label: 'Au moins 8 caractères', ok: _pwdNewController.text.length >= 8),
        (label: 'Une lettre majuscule', ok: RegExp(r'[A-Z]').hasMatch(_pwdNewController.text)),
        (label: 'Un chiffre', ok: RegExp(r'[0-9]').hasMatch(_pwdNewController.text)),
        (label: 'Un caractère spécial', ok: RegExp(r'[^a-zA-Z0-9]').hasMatch(_pwdNewController.text)),
      ];

  ({int score, Color color, String label}) get _pwdStrength {
    final score = _pwdCriteria.where((c) => c.ok).length;
    const levels = [
      (score: 1, color: Color(0xFFEF4444), label: 'Très faible'),
      (score: 2, color: Color(0xFFF97316), label: 'Faible'),
      (score: 3, color: Color(0xFFEAB308), label: 'Moyen'),
      (score: 4, color: Color(0xFF22C55E), label: 'Fort'),
    ];
    if (score == 0 || _pwdNewController.text.isEmpty) {
      return (score: 0, color: Colors.grey.shade300, label: '');
    }
    return levels[score - 1];
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final primary = Theme.of(context).colorScheme.primary;

    if (controller.isLoading && controller.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.hasError && controller.profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(controller.errorMessage ?? 'Impossible de charger le profil.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => controller.loadProfile(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = controller.profile;
    if (profile == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    _populateForm(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(primary),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final left = _buildLeftColumn(profile, controller, primary);
              final right = _buildRightColumn(profile, controller, primary);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: left),
                    const SizedBox(width: 20),
                    Expanded(child: right),
                  ],
                );
              }
              return Column(
                children: [
                  left,
                  const SizedBox(height: 16),
                  right,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Gérez vos informations personnelles et votre sécurité',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Chip(
          avatar: Icon(Icons.check_circle, size: 16, color: primary),
          label: const Text('Compte actif', style: TextStyle(fontSize: 12)),
          backgroundColor: primary.withValues(alpha: 0.1),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildLeftColumn(ProfileModel profile, ProfileController controller, Color primary) {
    return Column(
      children: [
        _buildIdentityCard(profile, controller, primary),
        const SizedBox(height: 12),
        _buildSecurityCard(profile, primary),
      ],
    );
  }

  Widget _buildIdentityCard(ProfileModel profile, ProfileController controller, Color primary) {
    final stats = controller.recStats;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.appBorder)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(
                  radius: 50,
                  initials: _initials(profile),
                  backgroundColor: _avatarColor(profile),
                  photoUrl: profile.photoUrl,
                  photoPath: profile.photoPath,
                  localFilePath: _localPhotoPath,
                  localBytes: _localPhotoBytes,
                  cacheBust: _photoCacheBust,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: controller.uploadingPhoto ? null : () => _pickPhoto(controller),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: controller.uploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName.isNotEmpty ? profile.fullName : profile.email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.appSurfaceLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                profile.matricule ?? '—',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: context.appMuted),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  label: Text(profile.niveau?.label ?? 'N/A', style: const TextStyle(fontSize: 11)),
                  backgroundColor: primary,
                  labelStyle: const TextStyle(color: Colors.white),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                Chip(
                  label: Text(profile.academicYear ?? '—', style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 32),
            _infoRow(Icons.email_outlined, profile.email, primary),
            _infoRow(Icons.phone_outlined, profile.phone ?? '—', primary),
            _infoRow(Icons.domain_outlined, profile.filiere?.name ?? '—', primary),
            _infoRow(Icons.location_on_outlined, profile.adresse ?? '—', primary),
            _infoRow(Icons.cake_outlined, _formatDate(profile.dateNaissance), primary),
            const Divider(height: 32),
            Row(
              children: [
                _statItem('${stats.total}', 'Total', primary),
                Container(width: 1, height: 32, color: Colors.grey.shade300),
                _statItem('${stats.pending}', 'En attente', Colors.orange),
                Container(width: 1, height: 32, color: Colors.grey.shade300),
                _statItem('${stats.resolved}', 'Résolues', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _statItem(String num, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(num, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey[600], letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(ProfileModel profile, Color primary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, size: 18, color: primary),
                const SizedBox(width: 8),
                Text('Sécurité du compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary)),
              ],
            ),
            const SizedBox(height: 12),
            _secRow(Icons.check_circle, Colors.green, 'Email vérifié'),
            const SizedBox(height: 8),
            _secRow(
              profile.passwordChangedAt != null ? Icons.check_circle : Icons.warning_amber,
              profile.passwordChangedAt != null ? Colors.green : Colors.orange,
              profile.passwordChangedAt != null
                  ? 'Mot de passe · modifié le ${_formatDate(profile.passwordChangedAt)}'
                  : 'Mot de passe · jamais modifié',
            ),
            if (profile.lastLoginAt != null) ...[
              const SizedBox(height: 8),
              _secRow(Icons.login, Colors.blue, 'Dernière connexion : ${_formatDateTime(profile.lastLoginAt)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _secRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }

  Widget _buildRightColumn(ProfileModel profile, ProfileController controller, Color primary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: const [
              Tab(icon: Icon(Icons.edit, size: 18), text: 'Informations'),
              Tab(icon: Icon(Icons.lock_outline, size: 18), text: 'Mot de passe'),
            ],
          ),
          const Divider(height: 1),
          if (_tabController.index == 0)
            _buildInfoTab(profile, controller, primary)
          else
            _buildPasswordTab(controller, primary),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 15, color: primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(ProfileModel profile, ProfileController controller, Color primary) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('Informations générales', Icons.person_outline, primary),
            LayoutBuilder(
              builder: (context, c) {
                final twoCol = c.maxWidth > 500;
                final fields = [
                  _field(_prenomController, 'Prénom', Icons.person_outline),
                  _field(_nomController, 'Nom de famille', Icons.person_outline),
                  _field(_emailController, 'Adresse email', Icons.email_outlined, type: TextInputType.emailAddress),
                  _field(_phoneController, 'Téléphone', Icons.phone_outlined, type: TextInputType.phone),
                ];
                if (!twoCol) {
                  return Column(children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: f)).toList());
                }
                return Column(
                  children: [
                    Row(children: [Expanded(child: fields[0]), const SizedBox(width: 16), Expanded(child: fields[1])]),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: fields[2]), const SizedBox(width: 16), Expanded(child: fields[3])]),
                  ],
                );
              },
            ),
            const Divider(height: 40),
            _sectionLabel('Informations complémentaires', Icons.info_outline, primary),
            LayoutBuilder(
              builder: (context, c) {
                final twoCol = c.maxWidth > 500;
                Widget row(List<Widget> children) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children
                          .expand((w) => [Expanded(child: w), if (w != children.last) const SizedBox(width: 16)])
                          .toList()
                        ..removeLast(),
                    );
                final w1 = _dateField();
                final w2 = _field(_lieuNaissanceController, 'Lieu de naissance', Icons.place_outlined);
                final w3 = _field(_nationaliteController, 'Nationalité', Icons.flag_outlined);
                final w4 = _field(_nniController, 'NNI', Icons.badge_outlined, readOnly: true);
                final w5 = _field(_adresseController, 'Adresse complète', Icons.home_outlined);
                if (!twoCol) {
                  return Column(
                    children: [w1, w2, w3, w4, w5]
                        .map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: f))
                        .toList(),
                  );
                }
                return Column(
                  children: [
                    row([w1, w2]),
                    const SizedBox(height: 16),
                    row([w3, w4]),
                    const SizedBox(height: 16),
                    w5,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildReadonlyBlock(profile),
            const SizedBox(height: 24),
            _actionButton(
              onPressed: controller.isUpdating ? null : () => _saveProfile(controller),
              icon: controller.isUpdating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: 'Enregistrer les modifications',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField() {
    return TextFormField(
      controller: _dateNaissanceController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date de naissance',
        prefixIcon: Icon(Icons.cake_outlined),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final initial = DateTime.tryParse(_dateNaissanceController.text) ?? DateTime(2000);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          locale: const Locale('fr'),
        );
        if (picked != null) {
          _dateNaissanceController.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly ? context.appSurfaceLow : null,
        helperText: readOnly ? 'Non modifiable' : null,
      ),
    );
  }

  Widget _buildReadonlyBlock(ProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 15, color: context.appMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'INFORMATIONS ACADÉMIQUES (NON MODIFIABLES)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.appMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _readonlyItem('Matricule', profile.matricule ?? '—', mono: true),
              _readonlyItem('Filière', profile.filiere?.name ?? '—'),
              _readonlyItem('Niveau', profile.niveau?.label ?? '—'),
              _readonlyItem('Année académique', profile.academicYear ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readonlyItem(String key, String value, {bool mono = false}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab(ProfileController controller, Color primary) {
    final strength = _pwdStrength;
    final pwdMatch = _pwdConfirmController.text.isNotEmpty && _pwdNewController.text == _pwdConfirmController.text;
    final pwdMismatch = _pwdConfirmController.text.isNotEmpty && !pwdMatch;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Changer le mot de passe', Icons.lock, primary),
          _pwdField(_pwdCurrentController, 'Mot de passe actuel', _showPwdCurrent, () => setState(() => _showPwdCurrent = !_showPwdCurrent)),
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nouveau mot de passe', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          _pwdField(_pwdNewController, 'Nouveau mot de passe', _showPwdNew, () => setState(() => _showPwdNew = !_showPwdNew)),
          if (_pwdNewController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i < strength.score ? strength.color : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
            if (strength.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(strength.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: strength.color)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _pwdCriteria.map((c) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.ok ? Icons.check_circle : Icons.circle_outlined, size: 12, color: c.ok ? Colors.green : Colors.grey),
                    const SizedBox(width: 4),
                    Text(c.label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          _pwdField(
            _pwdConfirmController,
            'Confirmer le nouveau mot de passe',
            _showPwdConfirm,
            () => setState(() => _showPwdConfirm = !_showPwdConfirm),
            errorText: pwdMismatch ? 'Les mots de passe ne correspondent pas' : null,
            helperText: pwdMatch ? 'Mots de passe identiques ✓' : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Utilisez au moins 8 caractères avec des majuscules, chiffres et symboles.',
                    style: TextStyle(fontSize: 12, color: context.appOnSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _actionButton(
            onPressed: (!_canSavePwd || controller.isUpdating) ? null : () => _savePassword(controller),
            icon: controller.isUpdating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock),
            label: 'Changer le mot de passe',
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth < 420;
        final button = FilledButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(label, overflow: TextOverflow.ellipsis),
        );
        if (fullWidth) {
          return SizedBox(width: double.infinity, child: button);
        }
        return Align(alignment: Alignment.centerRight, child: button);
      },
    );
  }

  Widget _pwdField(
    TextEditingController controller,
    String label,
    bool visible,
    VoidCallback onToggle, {
    String? errorText,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: const OutlineInputBorder(),
        errorText: errorText,
        helperText: helperText,
        helperStyle: helperText != null ? const TextStyle(color: Colors.green) : null,
      ),
    );
  }
}
