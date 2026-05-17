class ModuleModel {
  final int id;
  final String code;
  final String nom;
  final int? semestreId;
  final String? semestreCode;
  final double? coefficient;
  final int? credits;
  final String? createdAt;
  final String? updatedAt;

  ModuleModel({
    required this.id,
    required this.code,
    required this.nom,
    this.semestreId,
    this.semestreCode,
    this.coefficient,
    this.credits,
    this.createdAt,
    this.updatedAt,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'],
      code: json['code'],
      nom: json['nom'],
      semestreId: json['semestre_id'],
      semestreCode: json['semestre_code'],
      coefficient: json['coefficient'] != null ? (json['coefficient'] as num).toDouble() : null,
      credits: json['credits'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'nom': nom,
      'semestre_id': semestreId,
      'semestre_code': semestreCode,
      'coefficient': coefficient,
      'credits': credits,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
