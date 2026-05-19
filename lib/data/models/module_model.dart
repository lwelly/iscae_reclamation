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
      id: _asInt(json['id']),
      code: json['code']?.toString() ?? '',
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      semestreId: json['semestre_id'] != null ? _asInt(json['semestre_id']) : null,
      semestreCode: json['semestre_code']?.toString(),
      coefficient: _asDouble(json['coefficient']),
      credits: json['credits'] != null ? _asInt(json['credits']) : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
