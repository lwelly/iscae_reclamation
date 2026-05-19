import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../data/models/module_model.dart';
import '../../data/models/semestre_model.dart';
import 'reclamation_controller.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_ui_helpers.dart';

class CreateReclamationScreen extends StatefulWidget {
  const CreateReclamationScreen({super.key});

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

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final platformFile = result.files.single;
    if (platformFile.path == null) return;
    final file = File(platformFile.path!);
    final ext = platformFile.extension?.toLowerCase() ?? '';
    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(ext)) {
      setState(() => _errors['document'] = 'Type non accepté (PDF, JPG, PNG uniquement)');
      return;
    }
    final size = platformFile.size;
    if (size > _maxFileSize) {
      setState(() => _errors['document'] = 'Fichier trop volumineux (max 5 Mo)');
      return;
    }
    setState(() {
      _errors.remove('document');
      _docFile = file;
    });
  }

  void _removeDoc() {
    setState(() {
      _docFile = null;
      _errors.remove('document');
    });
  }

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
    if (e.isEmpty) setState(() => _step++);
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReclamationDetailScreen(id: newId)),
      );
    } else {
      setState(() => _globalError = controller.errorMessage ?? 'Une erreur inattendue est survenue.');
    }
  }

  void _notify(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 2),
      ),
    );
  }

  bool _isNarrow(BuildContext context) => MediaQuery.sizeOf(context).width < 520;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final narrow = _isNarrow(context);
    final hPad = narrow ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      if (_niveauCode.isNotEmpty) _buildInfoAlert('Vous êtes en $_niveauCode'),
                      if (!_loadingSemestres && _semestres.isEmpty)
                        _buildWarningAlert(
                          'Aucun semestre n\'est actuellement ouvert aux réclamations pour votre niveau $_niveauCode. Contactez l\'administration.',
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
    );
  }

  Widget _buildHeader(Color primary, {required bool narrow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réclamation',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Étape $_step sur 3 — ${_stepTitles[_step - 1]}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _step / 3, minHeight: 4, color: primary, backgroundColor: Colors.grey[200]),
        ),
        const SizedBox(height: 4),
        if (narrow)
          Text(
            _stepTitles[_step - 1],
            style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold),
          )
        else
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Text(
                  _stepTitles[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: _step > i ? primary : Colors.grey[600],
                    fontWeight: _step > i ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: i == 0 ? TextAlign.left : (i == 2 ? TextAlign.right : TextAlign.center),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildInfoAlert(String message) {
    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.school_outlined, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: Colors.blue[900], fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningAlert(String message) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.orange[800], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: Colors.orange[900], fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorAlert(String message) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: Colors.red[900], fontSize: 14))),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _globalError = '')),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({required String title, required String subtitle, required Widget child}) {
    final narrow = _isNarrow(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(narrow ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _buildStepCard(
      title: 'Informations de la réclamation',
      subtitle: 'Sélectionnez le semestre, le type et le module concerné',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _semestreId,
            decoration: InputDecoration(
              labelText: 'Semestre *',
              prefixIcon: const Icon(Icons.calendar_month),
              border: const OutlineInputBorder(),
              errorText: _errors['semestre_id'],
            ),
            hint: _loadingSemestres
                ? const Text('Chargement...', overflow: TextOverflow.ellipsis)
                : const Text('Aucun semestre disponible', overflow: TextOverflow.ellipsis),
            items: _semestres.map((s) {
              return DropdownMenuItem(
                value: s.id.toString(),
                child: Text(s.label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _loadingSemestres ? null : _onSemestreChanged,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Type de réclamation *', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (_errors['type'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_errors['type']!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          if (_semestreId == null)
            _buildHintBox('Sélectionnez d\'abord un semestre', Icons.info_outline)
          else if (_availableTypes.isEmpty)
            _buildHintBox('Aucun type disponible pour ce semestre', Icons.error_outline, isError: true)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final crossCount = w > 500 ? 3 : (w > 340 ? 2 : 1);
                final tileHeight = crossCount == 1 ? 96.0 : (crossCount == 2 ? 136.0 : 128.0);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: tileHeight,
                  ),
                  itemCount: _availableTypes.length,
                  itemBuilder: (context, index) {
                    final t = _availableTypes[index];
                    final selected = _type == t.value;
                    return GestureDetector(
                      onTap: () => _selectType(t.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selected ? t.bgColor : Colors.white,
                          border: Border.all(color: selected ? t.bgColor : Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selected
                              ? [BoxShadow(color: t.bgColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, color: selected ? Colors.white : t.color, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              t.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? Colors.white : null),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _moduleId,
            decoration: InputDecoration(
              labelText: 'Module concerné *',
              prefixIcon: const Icon(Icons.menu_book_outlined),
              border: const OutlineInputBorder(),
              errorText: _errors['module_id'],
            ),
            hint: Text(
              _loadingModules
                  ? 'Chargement...'
                  : (_semestreId == null
                      ? 'Sélectionnez un semestre'
                      : _modules.isEmpty
                          ? 'Aucun module disponible'
                          : 'Choisir un module'),
              overflow: TextOverflow.ellipsis,
            ),
            items: _modules.map((m) {
              return DropdownMenuItem(
                value: m.id.toString(),
                child: Text(
                  m.code.isNotEmpty ? '${m.nom} (${m.code})' : m.nom,
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteActuelleController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [_NoteDecimalTextInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Note actuelle *',
              prefixIcon: const Icon(Icons.numbers),
              suffixText: '/ 20',
              hintText: 'Entre 0 et 20 (ex: 12.5)',
              border: const OutlineInputBorder(),
              errorText: _errors['note_actuelle'],
            ),
            onChanged: (_) => setState(() => _errors.remove('note_actuelle')),
          ),
          if (_type == 'cc') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteReclameeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [_NoteDecimalTextInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Note réclamée',
                prefixIcon: const Icon(Icons.add_circle_outline),
                suffixText: '/ 20',
                hintText: 'Note que vous estimez mériter (optionnel)',
                border: const OutlineInputBorder(),
                errorText: _errors['note_reclamee'],
              ),
              onChanged: (_) => setState(() => _errors.remove('note_reclamee')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildStepCard(
      title: 'Justification',
      subtitle: 'Expliquez clairement le motif de votre réclamation.',
      child: Column(
        children: [
          TextFormField(
            controller: _justificationController,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Justification *',
              prefixIcon: const Icon(Icons.text_snippet_outlined),
              hintText: 'Minimum 20 caractères',
              border: const OutlineInputBorder(),
              errorText: _errors['justification'],
            ),
            onChanged: (_) => setState(() => _errors.remove('justification')),
          ),
          const SizedBox(height: 20),
          Text('Pièce jointe (optionnel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          if (_docFile == null)
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.35), width: 2, strokeAlign: BorderSide.strokeAlignInside),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    const Text(
                      'Cliquez pour ajouter un document',
                      style: TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'PDF, JPG ou PNG — max 5 Mo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(_fileIcon(_docFile!), color: _fileIconColor(_docFile!), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docFile!.path.split(Platform.pathSeparator).last,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ReclamationUi.formatFileSize(_docFile!.lengthSync()),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: _removeDoc),
                ],
              ),
            ),
          if (_errors['document'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errors['document']!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final recapEntries = <({Widget widget, bool fullWidth})>[
      (widget: _recapItem('Semestre', _currentSemestre?.label ?? '—'), fullWidth: false),
      (widget: _recapItem('Type', ReclamationUi.typeLabel(_type), chip: true, chipColor: ReclamationUi.typeColor(_type)), fullWidth: false),
      (widget: _recapItem('Module', _currentModule?.nom ?? '—'), fullWidth: false),
      (widget: _recapItem('Note actuelle', '${_formatNoteDisplay(_noteActuelleController.text)} / 20', bold: true), fullWidth: false),
      if (_type == 'cc' && _noteReclameeController.text.trim().isNotEmpty)
        (widget: _recapItem('Note réclamée', '${_formatNoteDisplay(_noteReclameeController.text)} / 20', bold: true), fullWidth: false),
      (widget: _recapItem('Justification', _justificationController.text, multiline: true), fullWidth: true),
      if (_docFile != null)
        (
          widget: _recapItem(
            'Pièce jointe',
            '${_docFile!.path.split(Platform.pathSeparator).last} (${ReclamationUi.formatFileSize(_docFile!.lengthSync())})',
          ),
          fullWidth: true,
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
                      if (i > 0) const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Je confirme que les informations ci-dessus sont exactes et je prends la responsabilité de cette réclamation.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.all(12),
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
            style: TextStyle(fontSize: 11, color: Colors.grey[600], letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (chip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: chipColor?.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                value,
                style: TextStyle(fontSize: 12, color: chipColor, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.w500),
              maxLines: multiline ? 6 : 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildHintBox(String text, IconData icon, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: isError ? Colors.red.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isError ? Colors.red : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: isError ? Colors.red : Colors.grey[600], fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildNavBar(Color primary, {required bool narrow}) {
    final prevBtn = OutlinedButton.icon(
      onPressed: _submitting ? null : () => setState(() => _step--),
      icon: const Icon(Icons.arrow_back),
      label: const Text('Précédent'),
    );
    final nextBtn = FilledButton.icon(
      onPressed: _canNext ? _goNext : null,
      icon: const Icon(Icons.arrow_forward),
      label: const Text('Suivant'),
    );
    final submitBtn = FilledButton.icon(
      onPressed: _confirmed && !_submitting ? _submit : null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      icon: _submitting
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle),
      label: Text(_submitting ? 'Soumission...' : 'Soumettre'),
    );

    return Container(
      padding: EdgeInsets.all(narrow ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step > 1) prevBtn,
                    if (_step > 1 && (_step < 3 || _step == 3)) const SizedBox(height: 8),
                    if (_step < 3) nextBtn else submitBtn,
                  ],
                )
              : Row(
                  children: [
                    if (_step > 1) prevBtn,
                    const Spacer(),
                    if (_step < 3) nextBtn else submitBtn,
                  ],
                ),
        ),
      ),
    );
  }

  IconData _fileIcon(File file) {
    final name = file.path.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _fileIconColor(File file) {
    final name = file.path.toLowerCase();
    if (name.endsWith('.pdf')) return Colors.red;
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) return Colors.blue;
    return Colors.grey;
  }
}

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

/// Valide une note sur /20 (0–20, max 2 décimales).
bool _isValidNoteValue(String text, {required bool required}) {
  final v = text.trim().replaceAll(',', '.');
  if (v.isEmpty) return !required;
  if (v.endsWith('.')) return false;
  final n = double.tryParse(v);
  return n != null && n >= 0 && n <= 20;
}

String _formatNoteDisplay(String text) {
  final v = text.trim().replaceAll(',', '.');
  if (v.isEmpty) return '—';
  final n = double.tryParse(v);
  if (n == null) return text;
  return _formatNoteNumber(n);
}

String _formatNoteNumber(double n) {
  final rounded = (n * 100).round() / 100;
  var s = rounded.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

String _sanitizeNoteInput(String val) {
  var s = val.replaceAll(',', '.');
  if (s.isEmpty) return s;

  final buf = StringBuffer();
  var dot = false;
  for (final c in s.split('')) {
    if (c == '.' && !dot) {
      dot = true;
      buf.write('.');
    } else if (RegExp(r'[0-9]').hasMatch(c)) {
      buf.write(c);
    }
  }
  s = buf.toString();
  if (s.isEmpty) return s;
  if (s == '.') return '0.';

  if (s.contains('.')) {
    final parts = s.split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      s = '${parts[0]}.${parts[1].substring(0, 2)}';
    }
  }

  if (s.endsWith('.')) {
    final head = s.substring(0, s.length - 1);
    if (head.isEmpty) return '0.';
    final n = double.tryParse(head);
    if (n != null && n > 20) return '20.';
    return s;
  }

  final n = double.tryParse(s);
  if (n == null) return s;
  if (n > 20) return _formatNoteNumber(20);
  if (n < 0) return '0';
  return _formatNoteNumber(n);
}

class _NoteDecimalTextInputFormatter extends TextInputFormatter {
  const _NoteDecimalTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final sanitized = _sanitizeNoteInput(newValue.text);
    if (sanitized == newValue.text) return newValue;
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}
