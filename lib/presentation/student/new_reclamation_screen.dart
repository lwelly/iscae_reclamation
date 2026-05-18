import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/semestre_model.dart';
import '../../../data/models/module_model.dart';
import '../../../data/models/reclamation_model.dart';
import '../../../core/config/api_config.dart';
import 'reclamation_controller.dart';

class NewReclamationScreen extends StatefulWidget {
  const NewReclamationScreen({super.key});

  @override
  State<NewReclamationScreen> createState() => _NewReclamationScreenState();
}

class _NewReclamationScreenState extends State<NewReclamationScreen> {
  int _currentStep = 1;
  final int _totalSteps = 3;

  // Text controllers
  final _noteActuelleController = TextEditingController();
  final _noteReclameeController = TextEditingController();
  final _justificationController = TextEditingController();

  // Form data
  String? _semestreId;
  String _type = '';
  String? _moduleId;
  File? _documentFile;

  // Loading states
  bool _loadingSemestres = false;
  bool _loadingModules = false;
  bool _submitting = false;
  bool _confirmed = false;

  // Data
  List<SemestreModel> _semestres = [];
  List<ModuleModel> _modules = [];
  String? _niveauCode;

  // Errors
  final Map<String, String> _errors = {};
  String _globalError = '';

  // Available types
  final List<ReclamationType> _allTypes = [
    ReclamationType(
      value: 'cc',
      label: 'Devoir',
      desc: 'Contrôle continu',
      icon: Icons.edit_note,
      color: Colors.blue,
      bgColor: const Color(0xFF1565C0),
    ),
    ReclamationType(
      value: 'examen',
      label: 'Examen',
      desc: 'Examen de fin de semestre',
      icon: Icons.description,
      color: Colors.orange,
      bgColor: const Color(0xFFE65100),
    ),
    ReclamationType(
      value: 'rattrapage',
      label: 'Rattrapage',
      desc: 'Session de rattrapage',
      icon: Icons.refresh,
      color: Colors.purple,
      bgColor: const Color(0xFF6A1B9A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSemestres();
  }

  Future<void> _loadSemestres() async {
    setState(() {
      _loadingSemestres = true;
    });
    try {
      final result = await ApiConfig().studentService.getSemestres();
      setState(() {
        _semestres = result;
        // Extract niveau from first semestre if available
        if (result.isNotEmpty) {
          _niveauCode = result.first.code?.substring(0, 2);
        }
      });
    } catch (e) {
      setState(() {
        _globalError = 'Impossible de charger les semestres: $e';
      });
    } finally {
      setState(() {
        _loadingSemestres = false;
      });
    }
  }

  Future<void> _loadModules(String semestreId) async {
    setState(() {
      _loadingModules = true;
      _modules = [];
    });
    try {
      final result = await ApiConfig().studentService.getModules(semestreId: int.parse(semestreId));
      setState(() {
        _modules = result;
      });
    } catch (e) {
      setState(() {
        _globalError = 'Impossible de charger les modules: $e';
      });
    } finally {
      setState(() {
        _loadingModules = false;
      });
    }
  }

  SemestreModel? get _currentSemestre {
    return _semestres.where((s) => s.id.toString() == _semestreId).firstOrNull;
  }

  List<ReclamationType> get _availableTypes {
    if (_currentSemestre == null) return [];
    final avail = _currentSemestre!.availableTypes;
    return _allTypes.where((t) => avail.contains(t.value)).toList();
  }

  ModuleModel? get _currentModule {
    return _modules.where((m) => m.id.toString() == _moduleId).firstOrNull;
  }

  bool get _canNext {
    if (_currentStep == 1) {
      final noteOk = _noteActuelleController.text.isNotEmpty &&
          double.tryParse(_noteActuelleController.text) != null &&
          double.parse(_noteActuelleController.text) >= 0 &&
          double.parse(_noteActuelleController.text) <= 20;
      final noteRecOk = _type != 'cc' ||
          _noteReclameeController.text.isEmpty ||
          (double.tryParse(_noteReclameeController.text) != null &&
              double.parse(_noteReclameeController.text) >= 0 &&
              double.parse(_noteReclameeController.text) <= 20);
      return _semestreId != null &&
          _type.isNotEmpty &&
          _moduleId != null &&
          noteOk &&
          noteRecOk;
    }
    if (_currentStep == 2) {
      return _justificationController.text.trim().length >= 20;
    }
    return true;
  }

  void _selectType(String value) {
    setState(() {
      _type = value;
      if (value != 'cc') {
        _noteReclameeController.clear();
      }
      _errors.remove('type');
    });
  }

  String _clampNote(String val) {
    if (val.isEmpty) return val;
    final n = double.tryParse(val);
    if (n == null) return '';
    if (n < 0) return '0';
    if (n > 20) return '20';
    return ((n * 100).round() / 100).toStringAsFixed(2);
  }

  void _goNext() {
    final errors = <String, String>{};

    if (_currentStep == 1) {
      if (_semestreId == null) errors['semestre_id'] = 'Sélectionnez un semestre';
      if (_type.isEmpty) errors['type'] = 'Sélectionnez un type';
      if (_moduleId == null) errors['module_id'] = 'Sélectionnez un module';

      final na = double.tryParse(_noteActuelleController.text);
      if (_noteActuelleController.text.isEmpty || na == null) {
        errors['note_actuelle'] = 'La note actuelle est obligatoire';
      } else if (na < 0 || na > 20) {
        errors['note_actuelle'] = 'La note doit être entre 0 et 20';
      }

      if (_type == 'cc' && _noteReclameeController.text.isNotEmpty) {
        final nr = double.tryParse(_noteReclameeController.text);
        if (nr == null || nr < 0 || nr > 20) {
          errors['note_reclamee'] = 'La note réclamée doit être entre 0 et 20';
        }
      }
    }

    if (_currentStep == 2) {
      if (_justificationController.text.trim().length < 20) {
        errors['justification'] = 'Minimum 20 caractères requis';
      }
    }

    setState(() {
      _errors.clear();
      _errors.addAll(errors);
    });

    if (errors.isEmpty) {
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _submit() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez cocher la case de confirmation.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _globalError = '';
    });

    try {
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
        file: _documentFile,
      );

      if (newId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réclamation soumise avec succès !')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _globalError = controller.errorMessage ?? 'Erreur lors de la soumission';
        });
      }
    } catch (e) {
      setState(() {
        _globalError = 'Erreur lors de la soumission: $e';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réclamation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 16),

            // Niveau alert
            if (_niveauCode != null)
              _buildInfoAlert('Vous êtes en $_niveauCode'),
            const SizedBox(height: 8),

            // No semestres alert
            if (!_loadingSemestres && _semestres.isEmpty)
              _buildWarningAlert('Aucun semestre n\'est actuellement ouvert aux réclamations pour votre niveau $_niveauCode. Contactez l\'administration.'),
            const SizedBox(height: 8),

            // Global error alert
            if (_globalError.isNotEmpty)
              _buildErrorAlert(_globalError),
            const SizedBox(height: 16),

            // Step content
            _buildStepContent(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape $_currentStep sur $_totalSteps — ${_getStepTitle(_currentStep)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _currentStep / _totalSteps,
          backgroundColor: Colors.grey[200],
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_totalSteps, (index) {
            final title = _getStepTitle(index + 1);
            return Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _currentStep > index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                fontWeight: _currentStep > index ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1: return 'Type & Module';
      case 2: return 'Justification';
      case 3: return 'Confirmation';
      default: return '';
    }
  }

  Widget _buildInfoAlert(String message) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.blue[900], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningAlert(String message) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.orange[900], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorAlert(String message) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red[900], fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => setState(() => _globalError = ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de la réclamation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sélectionnez le semestre, le type et le module concerné',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Semestre dropdown
            DropdownButtonFormField<String>(
              value: _semestreId,
              decoration: InputDecoration(
                labelText: 'Semestre *',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
                errorText: _errors['semestre_id'],
              ),
              items: _semestres.map((s) {
                return DropdownMenuItem(
                  value: s.id.toString(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.label),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 4,
                        children: (s.availableTypes).map((t) {
                          return Chip(
                            label: Text(_getTypeLabel(t), style: const TextStyle(fontSize: 10)),
                            backgroundColor: _getTypeColor(t).withOpacity(0.1),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _semestreId = value;
                  _type = '';
                  _moduleId = null;
                  _noteReclameeController.clear();
                  _errors.remove('semestre_id');
                  _errors.remove('type');
                  _errors.remove('module_id');
                });
                if (value != null) {
                  _loadModules(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Type selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type de réclamation *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_errors['type'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _errors['type']!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_semestreId == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Sélectionnez d\'abord un semestre', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  )
                else if (_availableTypes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Aucun type disponible pour ce semestre', style: TextStyle(color: Colors.red, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: _availableTypes.map((t) {
                      final isSelected = _type == t.value;
                      return GestureDetector(
                        onTap: () => _selectType(t.value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? t.bgColor : Colors.white,
                            border: Border.all(
                              color: isSelected ? t.bgColor : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: t.bgColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                t.icon,
                                color: isSelected ? Colors.white : t.color,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.desc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Module dropdown
            DropdownButtonFormField<String>(
              value: _moduleId,
              decoration: InputDecoration(
                labelText: 'Module concerné *',
                prefixIcon: const Icon(Icons.book),
                border: const OutlineInputBorder(),
                errorText: _errors['module_id'],
              ),
              items: _modules.map((m) {
                return DropdownMenuItem(
                  value: m.id.toString(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nom),
                      Text(
                        m.code,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _semestreId != null
                  ? (value) {
                      setState(() {
                        _moduleId = value;
                        _errors.remove('module_id');
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            // Note actuelle
            TextFormField(
              controller: _noteActuelleController,
              decoration: InputDecoration(
                labelText: 'Note actuelle *',
                prefixIcon: const Icon(Icons.format_list_numbered),
                suffixText: '/ 20',
                hintText: 'Entre 0 et 20 (ex: 12.5)',
                border: const OutlineInputBorder(),
                errorText: _errors['note_actuelle'],
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final clamped = _clampNote(value);
                if (clamped != value) {
                  _noteActuelleController.value = TextEditingValue(
                    text: clamped,
                    selection: TextSelection.collapsed(offset: clamped.length),
                  );
                }
                setState(() {
                  _errors.remove('note_actuelle');
                });
              },
            ),
            const SizedBox(height: 16),

            // Note réclamée (CC only)
            if (_type == 'cc')
              TextFormField(
                controller: _noteReclameeController,
                decoration: InputDecoration(
                  labelText: 'Note réclamée',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixText: '/ 20',
                  hintText: 'Note que vous estimez mériter (optionnel)',
                  border: const OutlineInputBorder(),
                  errorText: _errors['note_reclamee'],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final clamped = _clampNote(value);
                  if (clamped != value) {
                    _noteReclameeController.value = TextEditingValue(
                      text: clamped,
                      selection: TextSelection.collapsed(offset: clamped.length),
                    );
                  }
                  setState(() {
                    _errors.remove('note_reclamee');
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Justification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expliquez clairement le motif de votre réclamation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _justificationController,
              decoration: InputDecoration(
                labelText: 'Justification *',
                prefixIcon: const Icon(Icons.edit_note),
                hintText: 'Minimum 20 caractères',
                border: const OutlineInputBorder(),
                errorText: _errors['justification'],
              ),
              maxLines: 5,
              maxLength: 1000,
              onChanged: (value) {
                setState(() {
                  _errors.remove('justification');
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récapitulatif',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vérifiez les informations avant de soumettre',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildRecapItem('Semestre', _currentSemestre?.label ?? '—'),
                _buildRecapItem('Type', _getTypeLabel(_type), isChip: true, chipColor: _getTypeColor(_type)),
                _buildRecapItem('Module', _currentModule?.nom ?? '—'),
                _buildRecapItem('Note actuelle', '${_noteActuelleController.text} / 20', isBold: true),
                if (_type == 'cc' && _noteReclameeController.text.isNotEmpty)
                  _buildRecapItem('Note réclamée', '${_noteReclameeController.text} / 20', isBold: true),
                _buildRecapItem('Justification', _justificationController.text, isFullWidth: true),
              ],
            ),
            const SizedBox(height: 16),

            // Confirmation checkbox
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) {
                setState(() {
                  _confirmed = value ?? false;
                });
              },
              title: const Text(
                'Je confirme que les informations ci-dessus sont exactes et je prends la responsabilité de cette réclamation.',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapItem(String label, String value, {bool isChip = false, Color? chipColor, bool isBold = false, bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          if (isChip)
            Chip(
              label: Text(value, style: const TextStyle(fontSize: 12)),
              backgroundColor: chipColor?.withOpacity(0.1),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            OutlinedButton.icon(
              onPressed: _submitting ? null : () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
            ),
          const Spacer(),
          if (_currentStep < 3)
            ElevatedButton.icon(
              onPressed: _canNext ? _goNext : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Suivant'),
            )
          else
            ElevatedButton.icon(
              onPressed: _confirmed && !_submitting ? _submit : null,
              icon: const Icon(Icons.check_circle),
              label: _submitting ? const Text('Soumission...') : const Text('Soumettre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    final t = _allTypes.where((t) => t.value == type).firstOrNull;
    return t?.label ?? type;
  }

  Color _getTypeColor(String type) {
    final t = _allTypes.where((t) => t.value == type).firstOrNull;
    return t?.color ?? Colors.grey;
  }
}

class ReclamationType {
  final String value;
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final Color bgColor;

  ReclamationType({
    required this.value,
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
