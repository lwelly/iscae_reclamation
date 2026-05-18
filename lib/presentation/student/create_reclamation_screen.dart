import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reclamation_controller.dart';

class CreateReclamationScreen extends StatefulWidget {
  const CreateReclamationScreen({super.key});

  @override
  State<CreateReclamationScreen> createState() => _CreateReclamationScreenState();
}

class _CreateReclamationScreenState extends State<CreateReclamationScreen> {
  int _currentStep = 1;
  final List<String> _stepTitles = ['Type & Module', 'Justification', 'Confirmation'];

  // Données de formulaire
  String? _selectedSemestreId;
  String? _selectedType;
  String? _selectedModuleId;
  final TextEditingController _noteActuelleController = TextEditingController();
  final TextEditingController _noteReclameeController = TextEditingController();
  final TextEditingController _justificationController = TextEditingController();
  bool _isConfirmed = false;

  // États de chargement des listes distantes
  bool _loadingSemestres = false;
  bool _loadingModules = false;
  String _niveauCode = '';

  List<dynamic> _semestres = [];
  List<dynamic> _modules = [];
  Map<String, String> _fieldErrors = {};

  // Configuration des types de réclamation
  final List<Map<String, dynamic>> _allTypes = [
    {
      'value': 'cc',
      'label': 'Devoir',
      'desc': 'Contrôle continu',
      'icon': Icons.edit_note,
      'color': Colors.blue,
    },
    {
      'value': 'examen',
      'label': 'Examen',
      'desc': 'Examen de fin de semestre',
      'icon': Icons.description_outlined,
      'color': Colors.orange,
    },
    {
      'value': 'rattrapage',
      'label': 'Rattrapage',
      'desc': 'Session de rattrapage',
      'icon': Icons.refresh,
      'color': Colors.purple,
    },
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

  // ── Chargement des données d'API ───────────────────────────────────────────
  Future<void> _loadSemestres() async {
    if (!mounted) return;
    setState(() => _loadingSemestres = true);
    try {
      // Intégration ou simulation de tes endpoints ISCAE
      setState(() {
        _semestres = [
          {'id': '1', 'label': 'Semestre 1', 'available_types': ['cc', 'examen']},
          {'id': '2', 'label': 'Semestre 2', 'available_types': ['cc', 'examen', 'rattrapage']},
        ];
        _niveauCode = 'L3';
      });
    } catch (_) {
      _showSnackBar('Impossible de charger les semestres', Colors.red);
    } finally {
      if (mounted) setState(() => _loadingSemestres = false);
    }
  }

  Future<void> _loadModules(String semestreId) async {
    setState(() {
      _loadingModules = true;
      _modules = [];
      _selectedModuleId = null;
    });
    try {
      setState(() {
        _modules = [
          {'id': '10', 'code': 'M10', 'name': 'Management Control'},
          {'id': '11', 'code': 'M11', 'name': 'Oracle Database PL/SQL'},
        ];
      });
    } catch (_) {
      _showSnackBar('Impossible de charger les modules', Colors.red);
    } finally {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  // ── Validations des étapes ──────────────────────────────────────────────────
  bool get _canNext {
    if (_currentStep == 1) {
      final noteOk = _noteActuelleController.text.isNotEmpty &&
          double.tryParse(_noteActuelleController.text) != null &&
          double.parse(_noteActuelleController.text) >= 0 &&
          double.parse(_noteActuelleController.text) <= 20;

      final noteRecOk = _selectedType != 'cc' ||
          _noteReclameeController.text.isEmpty ||
          (double.tryParse(_noteReclameeController.text) != null &&
              double.parse(_noteReclameeController.text) >= 0 &&
              double.parse(_noteReclameeController.text) <= 20);

      return _selectedSemestreId != null && _selectedType != null && _selectedModuleId != null && noteOk && noteRecOk;
    }
    if (_currentStep == 2) {
      return _justificationController.text.trim().length >= 20;
    }
    return true;
  }

  void _goNext() {
    setState(() => _fieldErrors = {});
    Map<String, String> errors = {};

    if (_currentStep == 1) {
      if (_selectedSemestreId == null) errors['semestre_id'] = 'Sélectionnez un semestre';
      if (_selectedType == null) errors['type'] = 'Sélectionnez un type';
      if (_selectedModuleId == null) errors['module_id'] = 'Sélectionnez un module';
      if (_noteActuelleController.text.isEmpty) errors['note_actuelle'] = 'La note est obligatoire';
    } else if (_currentStep == 2) {
      if (_justificationController.text.trim().length < 20) {
        errors['justification'] = 'Minimum 20 caractères requis';
      }
    }

    if (errors.isEmpty) {
      setState(() => _currentStep++);
    } else {
      setState(() => _fieldErrors = errors);
    }
  }

  Future<void> _submitForm() async {
    if (!_isConfirmed) return;

    final controller = context.read<ReclamationController>();

    // Correction ici : Appel de 'submitReclamation' pour correspondre à ton controlleur
    final success = await controller.submitReclamation(
      semestreId: _selectedSemestreId!,
      moduleId: _selectedModuleId!,
      type: _selectedType!,
      noteActuelle: double.parse(_noteActuelleController.text),
      noteReclamee: _noteReclameeController.text.isNotEmpty ? double.parse(_noteReclameeController.text) : null,
      justification: _justificationController.text.trim(),
      file: null,
    );

    if (success && mounted) {
      _showSnackBar('Réclamation soumise avec succès !', Colors.green);
      controller.fetchReclamations();
      Navigator.pop(context);
    } else if (mounted && controller.errorMessage != null) {
      _showSnackBar(controller.errorMessage!, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ── Renders UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReclamationController>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle Réclamation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Étape $_currentStep sur 3 — ${_stepTitles[_currentStep - 1]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _currentStep / 3,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_niveauCode.isNotEmpty) _buildNiveauAlert(),
            const SizedBox(height: 12),
            if (_currentStep == 1) _buildStep1(),
            if (_currentStep == 2) _buildStep2(),
            if (_currentStep == 3) _buildStep3(),
            const SizedBox(height: 30),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNiveauAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: Colors.blue),
          const SizedBox(width: 10),
          Text('Vous êtes inscrit en : $_niveauCode', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // ÉTAPE 1 : Configuration
  // ══════════════════════════════════════════════════════════
  Widget _buildStep1() {
    final selectedSemObject = _semestres.firstWhere((s) => s['id'] == _selectedSemestreId, orElse: () => null);
    final List<dynamic> availableTypesRaw = selectedSemObject?['available_types'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedSemestreId,
          hint: const Text('Sélectionnez un semestre *'),
          decoration: InputDecoration(
            labelText: 'Semestre',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today),
            errorText: _fieldErrors['semestre_id'],
          ),
          items: _semestres.map<DropdownMenuItem<String>>((sem) {
            return DropdownMenuItem<String>(value: sem['id'], child: Text(sem['label']));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedSemestreId = val;
              _selectedType = null;
            });
            if (val != null) _loadModules(val);
          },
        ),
        const SizedBox(height: 20),
        const Text('Type de réclamation *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (_selectedSemestreId == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: const Text('Sélectionnez d\'abord un semestre', style: TextStyle(color: Colors.grey)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _allTypes.length,
            itemBuilder: (context, index) {
              final type = _allTypes[index];
              final isAllowed = availableTypesRaw.contains(type['value']);
              final isSelected = _selectedType == type['value'];

              return InkWell(
                onTap: isAllowed
                    ? () => setState(() {
                  _selectedType = type['value'];
                  if (_selectedType != 'cc') _noteReclameeController.clear();
                })
                    : null,
                child: Opacity(
                  opacity: isAllowed ? 1.0 : 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? type['color'] : Colors.transparent,
                      border: Border.all(color: isSelected ? type['color'] : Colors.grey[400]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type['icon'], color: isSelected ? Colors.white : type['color'], size: 28),
                        const SizedBox(height: 6),
                        Text(
                          type['label'],
                          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black, fontSize: 13),
                        ),
                        Text(
                          type['desc'],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (_fieldErrors['type'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_fieldErrors['type']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedModuleId,
          hint: const Text('Module concerné *'),
          decoration: InputDecoration(
            labelText: 'Module',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.book),
            errorText: _fieldErrors['module_id'],
          ),
          disabledHint: const Text('Sélectionnez d\'abord le semestre'),
          items: _modules.map<DropdownMenuItem<String>>((mod) {
            return DropdownMenuItem<String>(value: mod['id'], child: Text('${mod['code']} - ${mod['name']}'));
          }).toList(),
          onChanged: _selectedSemestreId == null ? null : (val) => setState(() => _selectedModuleId = val),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _noteActuelleController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Note actuelle *',
            hintText: 'Ex: 12.5',
            suffixText: '/ 20',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.pin),
            errorText: _fieldErrors['note_actuelle'],
          ),
        ),
        if (_selectedType == 'cc') ...[
          const SizedBox(height: 20),
          TextField(
            controller: _noteReclameeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Note estimée / réclamée (Optionnel)',
              hintText: 'Ex: 15.0',
              suffixText: '/ 20',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.plus_one),
            ),
          ),
        ]
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // ÉTAPE 2 : Justification
  // ══════════════════════════════════════════════════════════
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pourquoi contestez-vous cette note ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _justificationController,
          maxLines: 6,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'Expliquez clairement le motif (minimum 20 caractères)...',
            border: const OutlineInputBorder(),
            errorText: _fieldErrors['justification'],
          ),
          onChanged: (val) => setState(() {}),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // ÉTAPE 3 : Récapitulatif
  // ══════════════════════════════════════════════════════════
  Widget _buildStep3() {
    final semObject = _semestres.firstWhere((s) => s['id'] == _selectedSemestreId, orElse: () => {'label': '—'});
    final modObject = _modules.firstWhere((m) => m['id'] == _selectedModuleId, orElse: () => {'name': '—'});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Récapitulatif de votre demande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                _buildRecapRow('Semestre', semObject['label']),
                _buildRecapRow('Type', _selectedType?.toUpperCase() ?? ''),
                _buildRecapRow('Module', modObject['name']),
                _buildRecapRow('Note Actuelle', '${_noteActuelleController.text} / 20'),
                if (_selectedType == 'cc' && _noteReclameeController.text.isNotEmpty)
                  _buildRecapRow('Note Estimée', '${_noteReclameeController.text} / 20'),
                const Divider(),
                _buildRecapRow('Justification', _justificationController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _isConfirmed,
          title: const Text(
            'Je confirme que les informations ci-dessus sont exactes et je prends la responsabilité de cette demande.',
            style: TextStyle(fontSize: 13),
          ),
          onChanged: (val) => setState(() => _isConfirmed = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        )
      ],
    );
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 1)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Précédent'),
          )
        else
          const SizedBox(),
        if (_currentStep < 3)
          ElevatedButton.icon(
            onPressed: _canNext ? _goNext : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Suivant'),
          )
        else
          ElevatedButton.icon(
            onPressed: _isConfirmed ? _submitForm : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text('Soumettre', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}