class NoteModel {
  final int id;
  final String? matricule;
  final String? studentName;
  final String? moduleCode;
  final String? moduleName;
  final String? semestreCode;
  final String? type; // cc, examen, rattrapage
  final double? value;
  final double? coefficient;
  final String? createdAt;
  final String? updatedAt;

  NoteModel({
    required this.id,
    this.matricule,
    this.studentName,
    this.moduleCode,
    this.moduleName,
    this.semestreCode,
    this.type,
    this.value,
    this.coefficient,
    this.createdAt,
    this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      matricule: json['matricule'],
      studentName: json['student_name'],
      moduleCode: json['module_code'],
      moduleName: json['module_name'],
      semestreCode: json['semestre_code'],
      type: json['type'],
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      coefficient: json['coefficient'] != null ? (json['coefficient'] as num).toDouble() : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'student_name': studentName,
      'module_code': moduleCode,
      'module_name': moduleName,
      'semestre_code': semestreCode,
      'type': type,
      'value': value,
      'coefficient': coefficient,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
