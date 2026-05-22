import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/module_model.dart';
import '../../data/models/semestre_model.dart';
import 'reclamation_controller.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_ui_helpers.dart';

class CreateReclamationScreen extends StatefulWidget {
  /// Utilisé quand l'écran est intégré dans [MainLayoutScreen].
  final VoidCallback? onBackToDashboard;
  final void Function(int reclamationId)? onSubmittedDetail;

  const CreateReclamationScreen({
    super.key,
    this.onBackToDashboard,
    this.onSubmittedDetail,
  });

  @override
  State<CreateReclamationScreen> createState() => _CreateReclamationScreenState();
}

class _CreateReclamationScreenState extends State<CreateReclamationScreen> {
  static const _stepTitles = ['Type & Module', 'Justification', 'Confirmation'];
  static const _maxFileSize = 5 * 1024 * 1024;

  int _step = 1;
  bool _submitting = false;
  bool _confirmed = false;
  String _globalError = '';
  final Map<String, String> _errors = {};

  final _noteActuelleController = TextEditingController();
  final _noteReclameeController = TextEditingController();
  final _justificationController = TextEditingController();

  String? _semestreId;
  String _type = '';
  String? _moduleId;
  File? _docFile;
  String? _docFileName;
  int? _docFileSize;

  bool _loadingSemestres = false;
  bool _loadingModules = false;
  String _niveauCode = '';

  List<SemestreModel> _semestres = [];
  List<ModuleModel> _modules = [];

  final List<_ReclamationTypeDef> _allTypes = const [
    _ReclamationTypeDef(
      value: 'cc',
      label: 'Devoir',
      desc: 'Contrôle continu',
      icon: Icons.edit_note,
      color: Colors.blue,
      bgColor: Color(0xFF1565C0),
    ),
    _ReclamationTypeDef(
      value: 'examen',
      label: 'Examen',
      desc: 'Examen de fin de semestre',
      icon: Icons.description_outlined,
      color: Colors.orange,
      bgColor: Color(0xFFE65100),
    ),
    _ReclamationTypeDef(
      value: 'rattrapage',
      label: 'Rattrapage',
      desc: 'Session de rattrapage',
      icon: Icons.refresh,
      color: Colors.purple,
      bgColor: Color(0xFF6A1B9A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSemestres();
  }

  @override
  void dispose() {
    _noteActuelleController.dispose();
    _noteReclameeController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  SemestreModel? get _currentSemestre =>
      _semestres.where((s) => s.id.toString() == _semestreId).firstOrNull;

  List<_ReclamationTypeDef> get _availableTypes {
    if (_currentSemestre == null) return [];
    final avail = _currentSemestre!.availableTypes;
    return _allTypes.where((t) => avail.contains(t.value)).toList();
  }

  ModuleModel? get _currentModule =>
      _modules.where((m) => m.id.toString() == _moduleId).firstOrNull;

  Future<void> _loadSemestres() async {
    setState(() => _loadingSemestres = true);
    try {
      final result = await ApiConfig().studentService.getSemestresWithNiveau();
      setState(() {
        _semestres = result.semestres;
        _niveauCode = result.niveau;
      });
    } catch (_) {
      _notify('Impossible de charger les semestres', isError: true);
    } finally {
      if (mounted) setState(() => _loadingSemestres = false);
    }
  }

  Future<void> _loadModules(String semestreId) async {
    setState(() {
      _loadingModules = true;
      _modules = [];
      _moduleId = null;
    });
    try {
      final result = await ApiConfig().studentService.getModules(semestreId: int.parse(semestreId));
      setState(() => _modules = result);
    } catch (e) {
      _notify('Impossible de charger les modules: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  bool _isValidNoteValue(String val, {required bool required}) {
    if (val.trim().isEmpty) return !required;
    final n = double.tryParse(val.trim().replaceAll(',', '.'));
    return n != null && n >= 0 && n <= 20;
  }

  String _formatNoteDisplay(String val) => val.trim().replaceAll(',', '.');

  bool get _canNext {
    if (_step == 1) {
      final noteOk = _isValidNoteValue(_noteActuelleController.text, required: true);
      final noteRecOk = _type != 'cc' ||
          _noteReclameeController.text.trim().isEmpty ||
          _isValidNoteValue(_noteReclameeController.text, required: false);
      return _semestreId != null && _type.isNotEmpty && _moduleId != null && noteOk && noteRecOk;
    }
    if (_step == 2) {
      return _justificationController.text.trim().length >= 20;
    }
    return true;
  }

  double? _parseNote(String text) {
    final v = text.trim().replaceAll(',', '.');
    if (!_isValidNoteValue(v, required: true)) return null;
    return double.parse(v);
  }

  void _selectType(String value) {
    setState(() {
      _type = value;
      if (value != 'cc') _noteReclameeController.clear();
      _errors.remove('type');
    });
  }

  void _onSemestreChanged(String? value) {
    setState(() {
      _semestreId = value;
      _type = '';
      _moduleId = null;
      _noteActuelleController.clear();
      _noteReclameeController.clear();
      _errors.clear();
    });
    if (value != null) _loadModules(value);
  }

  // ── Document Upload ──────────────────────────────────────────────────────────
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final platformFile = result.files.single;
    if (platformFile.path == null) return;
    final ext = platformFile.extension?.toLowerCase() ?? '';
    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(ext)) {
      setState(() => _errors['document'] = 'Type non accepté (PDF, JPG, PNG uniquement)');
      return;
    }
    if (platformFile.size > _maxFileSize) {
      setState(() => _errors['document'] = 'Fichier trop volumineux (max 5 Mo)');
      return;
    }
    setState(() {
      _errors.remove('document');
      _docFile = File(platformFile.path!);
      _docFileName = platformFile.name;
      _docFileSize = platformFile.size;
    });
  }

  void _removeDoc() {
    setState(() {
      _docFile = null;
      _docFileName = null;
      _docFileSize = null;
      _errors.remove('document');
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _fileIconColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Colors.red;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Colors.blue;
    return Colors.grey;
  }

  // ── Navigation ───────────────────────────────────────────────────────────────
  void _goNext() {
    final e = <String, String>{};
    if (_step == 1) {
      if (_semestreId == null) e['semestre_id'] = 'Sélectionnez un semestre';
      if (_type.isEmpty) e['type'] = 'Sélectionnez un type';
      if (_moduleId == null) e['module_id'] = 'Sélectionnez un module';
      if (!_isValidNoteValue(_noteActuelleController.text, required: true)) {
        final raw = _noteActuelleController.text.trim();
        if (raw.isEmpty) {
          e['note_actuelle'] = 'La note actuelle est obligatoire';
        } else if (raw.endsWith('.')) {
          e['note_actuelle'] = 'Saisissez une note complète (ex: 12.5)';
        } else {
          e['note_actuelle'] = 'La note doit être entre 0 et 20';
        }
      }
      if (_type == 'cc' && _noteReclameeController.text.trim().isNotEmpty) {
        if (!_isValidNoteValue(_noteReclameeController.text, required: false)) {
          final raw = _noteReclameeController.text.trim();
          e['note_reclamee'] = raw.endsWith('.')
              ? 'Saisissez une note complète (ex: 14)'
              : 'La note réclamée doit être entre 0 et 20';
        }
      }
    }
    if (_step == 2) {
      if (_justificationController.text.trim().length < 20) {
        e['justification'] = 'Minimum 20 caractères requis';
      }
    }
    setState(() => _errors
      ..clear()
      ..addAll(e));
    if (e.isEmpty && _step < 3) setState(() => _step++);
  }

  Future<void> _submit() async {
    if (!_confirmed) {
      _notify('Veuillez cocher la case de confirmation.', isError: true);
      return;
    }
    setState(() {
      _submitting = true;
      _globalError = '';
    });
    final controller = context.read<ReclamationController>();
    final newId = await controller.submitReclamation(
      semestreId: _semestreId!,
      moduleId: _moduleId!,
      type: _type,
      noteActuelle: _parseNote(_noteActuelleController.text)!,
      noteReclamee: _type == 'cc' && _noteReclameeController.text.trim().isNotEmpty
          ? _parseNote(_noteReclameeController.text)
          : null,
      justification: _justificationController.text.trim(),
      file: _docFile,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (newId != null) {
      _notify('Réclamation soumise avec succès ! Redirection…');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (widget.onSubmittedDetail != null) {
        widget.onSubmittedDetail!(newId);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ReclamationDetailScreen(id: newId)),
        );
      }
    } else {
      setState(() => _globalError =
          controller.errorMessage ?? 'Une erreur inattendue est survenue.');
    }
  }

  void _notify(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 2),
      ),
    );
  }

  void _handleBackPressed() {
    if (_step > 1) {
      setState(() => _step--);
      return;
    }
    if (widget.onBackToDashboard != null) {
      widget.onBackToDashboard!();
      return;
    }
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  bool _isNarrow(BuildContext context) => MediaQuery.sizeOf(context).width < 520;

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final narrow = _isNarrow(context);
    final hPad = narrow ? 16.0 : 24.0;

    return PopScope(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(primary, narrow: narrow),
                        const SizedBox(height: 16),
                        if (_niveauCode.isNotEmpty)
                          _buildInfoAlert('Vous êtes en $_niveauCode'),
                        if (!_loadingSemestres && _semestres.isEmpty)
                          _buildWarningAlert(
                            'Aucun semestre n\'est actuellement ouvert aux réclamations'
                                ' pour votre niveau $_niveauCode. Contactez l\'administration.',
                          ),
                        if (_globalError.isNotEmpty) _buildErrorAlert(_globalError),
                        const SizedBox(height: 8),
                        if (_step == 1) _buildStep1(),
                        if (_step == 2) _buildStep2(),
                        if (_step == 3) _buildStep3(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildNavBar(primary, narrow: narrow),
          ],
        ),
      ),
    );
  }

  // ── En-tête avec barre de progression ────────────────────────────────────────
  Widget _buildHeader(Color primary, {required bool narrow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape $_step sur 3 — ${_stepTitles[_step - 1]}',
          style: TextStyle(
            fontSize: 12,           // était 14
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _step / 3,
            minHeight: 4,
            color: primary,
            backgroundColor: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 8),
        if (!narrow)
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Text(
                  _stepTitles[i],
                  style: TextStyle(
                    fontSize: 11,   // était 12
                    color: _step > i ? primary : Colors.grey[600],
                    fontWeight: _step > i ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: i == 0
                      ? TextAlign.left
                      : (i == 2 ? TextAlign.right : TextAlign.center),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
      ],
    );
  }

  // ── Alertes ──────────────────────────────────────────────────────────────────
  Widget _buildInfoAlert(String message) {
    return _AlertBanner(
      color: Colors.blue,
      icon: Icons.school_outlined,
      message: message,
      onClose: null,
    );
  }

  Widget _buildWarningAlert(String message) {
    return _AlertBanner(
      color: Colors.orange,
      icon: Icons.calendar_month_outlined,
      message: message,
      onClose: null,
    );
  }

  Widget _buildErrorAlert(String message) {
    return _AlertBanner(
      color: Colors.red,
      icon: Icons.error_outline,
      message: message,
      onClose: () => setState(() => _globalError = ''),
    );
  }

  // ── Wrapper carte d'étape ─────────────────────────────────────────────────────
  Widget _buildStepCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final narrow = _isNarrow(context);
    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appBorder),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(narrow ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,           // était 18
                fontWeight: FontWeight.bold,
                color: context.appOnSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: context.appMuted), // était 14
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // ── Carte type de réclamation ─────────────────────────────────────────────────
  Widget _buildTypeCard(_ReclamationTypeDef t) {
    final selected = _type == t.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectType(t.value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? t.color.withValues(alpha: context.isDarkMode ? 0.16 : 0.06)
                : context.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? t.color : context.appBorder,
              width: selected ? 2 : 1,
            ),
            boxShadow: context.isDarkMode
                ? null
                : [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: selected ? 0.07 : 0.04),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.color.withValues(alpha: context.isDarkMode ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(t.icon, color: t.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: t.color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ÉTAPE 1 — Type, Semestre, Module, Notes
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return _buildStepCard(
      title: 'Informations de la réclamation',
      subtitle: 'Sélectionnez le semestre, le type et le module concerné',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Semestre ──
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _semestreId,
            style: TextStyle(fontSize: 13, color: context.appOnSurface), // fix couleur texte
            decoration: InputDecoration(
              labelText: 'Semestre *',
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.calendar_month, size: 18),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              errorText: _errors['semestre_id'],
              errorStyle: const TextStyle(fontSize: 11),
            ),
            hint: _loadingSemestres
                ? const Text('Chargement...', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)
                : const Text('Sélectionnez un semestre', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
            items: _semestres.map((s) {
              final chips = (s.availableTypes).map((t) {
                final def = _allTypes.firstWhere(
                      (d) => d.value == t,
                  orElse: () => _allTypes.first,
                );
                return def;
              }).toList();
              return DropdownMenuItem<String>(
                value: s.id.toString(),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.label, style: TextStyle(fontSize: 12, color: context.appOnSurface), overflow: TextOverflow.ellipsis),
                    ),
                    ...chips.map(
                          (def) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: _TypeChip(def: def),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: _loadingSemestres ? null : _onSemestreChanged,
          ),
          const SizedBox(height: 18),

          // ── Type de réclamation ──
          Text(
            'Type de réclamation',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,           // était 14
              color: context.appOnSurface,
            ),
          ),
          if (_errors['type'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errors['type']!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 11,       // était 12
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (_semestreId == null)
            _buildHintBox('Sélectionnez d\'abord un semestre', Icons.info_outline)
          else if (_availableTypes.isEmpty)
            _buildHintBox(
              'Aucun type disponible pour ce semestre',
              Icons.error_outline,
              isError: true,
            )
          else
            Column(
              children: _availableTypes.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTypeCard(t),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // ── Module ──
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _moduleId,
            style: TextStyle(fontSize: 13, color: context.appOnSurface), // fix couleur texte
            decoration: InputDecoration(
              labelText: 'Module concerné *',
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.menu_book_outlined, size: 18),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              errorText: _errors['module_id'],
              errorStyle: const TextStyle(fontSize: 11),
            ),
            hint: Text(
              _loadingModules
                  ? 'Chargement...'
                  : (_semestreId == null
                  ? 'Sélectionnez un semestre d\'abord'
                  : _modules.isEmpty
                  ? 'Aucun module disponible'
                  : 'Choisir un module'),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            items: _modules.map((m) {
              return DropdownMenuItem<String>(
                value: m.id.toString(),
                child: Text(
                  m.code.isNotEmpty ? '${m.nom} (${m.code})' : m.nom,
                  style: TextStyle(fontSize: 12, color: context.appOnSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _semestreId == null
                ? null
                : (v) => setState(() {
              _moduleId = v;
              _errors.remove('module_id');
            }),
          ),
          const SizedBox(height: 18),

          // ── Note actuelle ──
          TextFormField(
            controller: _noteActuelleController,
            style: TextStyle(fontSize: 13, color: context.appOnSurface), // fix couleur texte
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))
            ],
            decoration: InputDecoration(
              labelText: 'Note actuelle *',
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.numbers, size: 18),
              suffixText: '/ 20',
              hintText: 'Ex: 12.5',
              hintStyle: const TextStyle(fontSize: 12),
              helperText: 'Entre 0 et 20',
              helperStyle: const TextStyle(fontSize: 11),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              errorText: _errors['note_actuelle'],
              errorStyle: const TextStyle(fontSize: 11),
            ),
            onChanged: (_) => setState(() => _errors.remove('note_actuelle')),
          ),

          // ── Note réclamée (CC uniquement) ──
          if (_type == 'cc') ...[
            const SizedBox(height: 18),
            TextFormField(
              controller: _noteReclameeController,
              style: TextStyle(fontSize: 13, color: context.appOnSurface), // fix couleur texte
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))
              ],
              decoration: InputDecoration(
                labelText: 'Note réclamée',
                labelStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                suffixText: '/ 20',
                hintText: 'Ex: 14',
                hintStyle: const TextStyle(fontSize: 12),
                helperText: 'Note que vous estimez mériter',
                helperStyle: const TextStyle(fontSize: 11),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                errorText: _errors['note_reclamee'],
                errorStyle: const TextStyle(fontSize: 11),
              ),
              onChanged: (_) => setState(() => _errors.remove('note_reclamee')),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ÉTAPE 2 — Justification & Document
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildStep2() {
    return _buildStepCard(
      title: 'Justification',
      subtitle: 'Expliquez clairement le motif de votre réclamation.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Justification ──
          TextFormField(
            controller: _justificationController,
            style: TextStyle(fontSize: 13, color: context.appOnSurface), // fix couleur texte
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Justification *',
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.text_snippet_outlined, size: 18),
              hintText: 'Minimum 20 caractères',
              hintStyle: const TextStyle(fontSize: 12),
              helperText: 'Minimum 20 caractères',
              helperStyle: const TextStyle(fontSize: 11),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              errorText: _errors['justification'],
              errorStyle: const TextStyle(fontSize: 11),
            ),
            onChanged: (_) => setState(() => _errors.remove('justification')),
          ),
        ],
      ),
    );
  }

  /// Aperçu du fichier sélectionné
  Widget _buildFilePreview() {
    final primary = Theme.of(context).colorScheme.primary;
    final name = _docFileName ?? _docFile!.path.split('/').last;
    final size = _docFileSize ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_fileIcon(name), color: _fileIconColor(name), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12), // était 14
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSize(size),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]), // était 12
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey[600],
            onPressed: _removeDoc,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ÉTAPE 3 — Confirmation / Récapitulatif
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildStep3() {
    final recapEntries = <({Widget widget, bool fullWidth})>[
      (
      widget: _recapItem('Semestre', _currentSemestre?.label ?? '—'),
      fullWidth: false
      ),
      (
      widget: _recapItem(
        'Type',
        ReclamationUi.typeLabel(_type),
        chip: true,
        chipColor: ReclamationUi.typeColor(_type),
      ),
      fullWidth: false
      ),
      (
      widget: _recapItem('Module', _currentModule?.nom ?? '—'),
      fullWidth: false
      ),
      (
      widget: _recapItem(
        'Note actuelle',
        '${_formatNoteDisplay(_noteActuelleController.text)} / 20',
        bold: true,
      ),
      fullWidth: false
      ),
      if (_type == 'cc' && _noteReclameeController.text.trim().isNotEmpty)
        (
        widget: _recapItem(
          'Note réclamée',
          '${_formatNoteDisplay(_noteReclameeController.text)} / 20',
          bold: true,
        ),
        fullWidth: false
        ),
      (
      widget: _recapItem(
        'Justification',
        _justificationController.text,
        multiline: true,
      ),
      fullWidth: true
      ),
      if (_docFile != null)
        (
        widget: _recapItem(
          'Pièce jointe',
          _docFileName ?? _docFile!.path.split('/').last,
        ),
        fullWidth: false
        ),
    ];

    return _buildStepCard(
      title: 'Récapitulatif',
      subtitle: 'Vérifiez les informations avant de soumettre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < recapEntries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      recapEntries[i].widget,
                    ],
                  ],
                );
              }
              final halfWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: recapEntries.map((entry) {
                  final w = entry.fullWidth ? constraints.maxWidth : halfWidth;
                  return SizedBox(width: w, child: entry.widget);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Je confirme que les informations ci-dessus sont exactes et je prends'
                  ' la responsabilité de cette réclamation.',
              style: TextStyle(fontSize: 12), // était 14
            ),
          ),
        ],
      ),
    );
  }

  // ── Éléments du récapitulatif ─────────────────────────────────────────────────
  Widget _recapItem(
      String label,
      String value, {
        bool chip = false,
        Color? chipColor,
        bool bold = false,
        bool multiline = false,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,           // était 11
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (chip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: chipColor?.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,       // était 12
                  color: chipColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 12,         // était 14
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: multiline ? 6 : 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // ── Boîte d'indice ────────────────────────────────────────────────────────────
  Widget _buildHintBox(String text, IconData icon, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isError ? Colors.red.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isError ? Colors.red : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,         // était 13
                color: isError ? Colors.red.shade900 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de navigation ───────────────────────────────────────────────────────
  Widget _buildNavBar(Color primary, {required bool narrow}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 14),
      decoration: BoxDecoration(
        color: context.appNavBar,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1)
            OutlinedButton.icon(
              onPressed: _submitting ? null : () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('Précédent', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (_step < 3)
            FilledButton.icon(
              onPressed: _canNext ? _goNext : null,
              label: const Text('Suivant', style: TextStyle(fontSize: 12)),
              icon: const Icon(Icons.arrow_forward, size: 14),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            FilledButton.icon(
              onPressed: (_confirmed && !_submitting) ? _submit : null,
              label: _submitting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Soumettre', style: TextStyle(fontSize: 12)),
              icon: _submitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send, size: 14),
              style: FilledButton.styleFrom(
                backgroundColor: _confirmed ? Colors.green : null,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Widgets utilitaires
// ════════════════════════════════════════════════════════════════════════════════

/// Bannière d'alerte réutilisable (info / warning / error)
class _AlertBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  final VoidCallback? onClose;

  const _AlertBanner({
    required this.color,
    required this.icon,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 12,     // était 14
                ),
              ),
            ),
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 14, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mini chip coloré affiché dans le dropdown semestre
class _TypeChip extends StatelessWidget {
  final _ReclamationTypeDef def;
  const _TypeChip({required this.def});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: def.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        def.label,
        style: TextStyle(
          fontSize: 10,
          color: def.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Définition interne d'un type de réclamation
class _ReclamationTypeDef {
  final String value;
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _ReclamationTypeDef({
    required this.value,
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}