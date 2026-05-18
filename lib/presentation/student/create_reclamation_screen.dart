import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
    } catch (_) {
      _notify('Impossible de charger les modules', isError: true);
    } finally {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  bool get _canNext {
    if (_step == 1) {
      final noteOk = _noteActuelleController.text.isNotEmpty &&
          double.tryParse(_noteActuelleController.text) != null &&
          double.parse(_noteActuelleController.text) >= 0 &&
          double.parse(_noteActuelleController.text) <= 20;
      final noteRecOk = _type != 'cc' ||
          _noteReclameeController.text.isEmpty ||
          (double.tryParse(_noteReclameeController.text) != null &&
              double.parse(_noteReclameeController.text) >= 0 &&
              double.parse(_noteReclameeController.text) <= 20);
      return _semestreId != null && _type.isNotEmpty && _moduleId != null && noteOk && noteRecOk;
    }
    if (_step == 2) {
      return _justificationController.text.trim().length >= 20;
    }
    return true;
  }

  String _clampNote(String val) {
    if (val.isEmpty) return val;
    final n = double.tryParse(val);
    if (n == null) return '';
    if (n < 0) return '0';
    if (n > 20) return '20';
    return ((n * 100).round() / 100).toStringAsFixed(2);
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
      final na = double.tryParse(_noteActuelleController.text);
      if (_noteActuelleController.text.isEmpty || na == null) {
        e['note_actuelle'] = 'La note actuelle est obligatoire';
      } else if (na < 0 || na > 20) {
        e['note_actuelle'] = 'La note doit être entre 0 et 20';
      }
      if (_type == 'cc' && _noteReclameeController.text.isNotEmpty) {
        final nr = double.tryParse(_noteReclameeController.text);
        if (nr == null || nr < 0 || nr > 20) {
          e['note_reclamee'] = 'La note réclamée doit être entre 0 et 20';
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
      noteActuelle: double.parse(_noteActuelleController.text),
      noteReclamee: _type == 'cc' && _noteReclameeController.text.isNotEmpty
          ? double.parse(_noteReclameeController.text)
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(primary),
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
          _buildNavBar(primary),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Réclamation', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(
          'Étape $_step sur 3 — ${_stepTitles[_step - 1]}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _step / 3, minHeight: 4, color: primary, backgroundColor: Colors.grey[200]),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            return Text(
              _stepTitles[i],
              style: TextStyle(
                fontSize: 12,
                color: _step > i ? primary : Colors.grey[600],
                fontWeight: _step > i ? FontWeight.bold : FontWeight.normal,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            value: _semestreId,
            decoration: InputDecoration(
              labelText: 'Semestre *',
              prefixIcon: const Icon(Icons.calendar_month),
              border: const OutlineInputBorder(),
              errorText: _errors['semestre_id'],
            ),
            hint: _loadingSemestres ? const Text('Chargement...') : const Text('Aucun semestre disponible'),
            items: _semestres.map((s) {
              return DropdownMenuItem(
                value: s.id.toString(),
                child: Row(
                  children: [
                    Expanded(child: Text(s.label)),
                    const SizedBox(width: 8),
                    ...s.availableTypes.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Chip(
                            label: Text(ReclamationUi.typeLabel(t), style: const TextStyle(fontSize: 10)),
                            backgroundColor: ReclamationUi.typeBg(t),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
                  ],
                ),
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
                final crossCount = constraints.maxWidth > 500 ? 3 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: _availableTypes.map((t) {
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t.icon, color: selected ? Colors.white : t.color, size: 28),
                            const SizedBox(height: 8),
                            Text(t.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? Colors.white : null)),
                            Text(
                              t.desc,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _moduleId,
            decoration: InputDecoration(
              labelText: 'Module concerné *',
              prefixIcon: const Icon(Icons.menu_book_outlined),
              border: const OutlineInputBorder(),
              errorText: _errors['module_id'],
            ),
            hint: Text(_loadingModules ? 'Chargement...' : 'Aucun module disponible'),
            items: _modules.map((m) {
              return DropdownMenuItem(
                value: m.id.toString(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.nom),
                    Text(m.code, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
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
            decoration: InputDecoration(
              labelText: 'Note actuelle *',
              prefixIcon: const Icon(Icons.numbers),
              suffixText: '/ 20',
              hintText: 'Entre 0 et 20 (ex: 12.5)',
              border: const OutlineInputBorder(),
              errorText: _errors['note_actuelle'],
            ),
            onChanged: (v) {
              final c = _clampNote(v);
              if (c != v) {
                _noteActuelleController.value = TextEditingValue(text: c, selection: TextSelection.collapsed(offset: c.length));
              }
              setState(() => _errors.remove('note_actuelle'));
            },
          ),
          if (_type == 'cc') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteReclameeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Note réclamée',
                prefixIcon: const Icon(Icons.add_circle_outline),
                suffixText: '/ 20',
                hintText: 'Note que vous estimez mériter (optionnel)',
                border: const OutlineInputBorder(),
                errorText: _errors['note_reclamee'],
              ),
              onChanged: (v) {
                final c = _clampNote(v);
                if (c != v) {
                  _noteReclameeController.value = TextEditingValue(text: c, selection: TextSelection.collapsed(offset: c.length));
                }
                setState(() => _errors.remove('note_reclamee'));
              },
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
                    const Text('Cliquez pour ajouter un document', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('PDF, JPG ou PNG — max 5 Mo', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
    return _buildStepCard(
      title: 'Récapitulatif',
      subtitle: 'Vérifiez les informations avant de soumettre',
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _recapItem('Semestre', _currentSemestre?.label ?? '—'),
              _recapItem('Type', ReclamationUi.typeLabel(_type), chip: true, chipColor: ReclamationUi.typeColor(_type)),
              _recapItem('Module', _currentModule?.nom ?? '—'),
              _recapItem('Note actuelle', '${_noteActuelleController.text} / 20', bold: true),
              if (_type == 'cc' && _noteReclameeController.text.isNotEmpty)
                _recapItem('Note réclamée', '${_noteReclameeController.text} / 20', bold: true),
              _recapItem('Justification', _justificationController.text, fullWidth: true),
              if (_docFile != null)
                _recapItem(
                  'Pièce jointe',
                  '${_docFile!.path.split(Platform.pathSeparator).last} (${ReclamationUi.formatFileSize(_docFile!.lengthSync())})',
                ),
            ],
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

  Widget _recapItem(String label, String value, {bool chip = false, Color? chipColor, bool bold = false, bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[600], letterSpacing: 0.5)),
          const SizedBox(height: 4),
          if (chip)
            Chip(
              label: Text(value, style: TextStyle(fontSize: 12, color: chipColor, fontWeight: FontWeight.w600)),
              backgroundColor: chipColor?.withOpacity(0.12),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
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

  Widget _buildNavBar(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Row(
            children: [
              if (_step > 1)
                OutlinedButton.icon(
                  onPressed: _submitting ? null : () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Précédent'),
                ),
              const Spacer(),
              if (_step < 3)
                FilledButton.icon(
                  onPressed: _canNext ? _goNext : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Suivant'),
                )
              else
                FilledButton.icon(
                  onPressed: _confirmed && !_submitting ? _submit : null,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle),
                  label: Text(_submitting ? 'Soumission...' : 'Soumettre'),
                ),
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
