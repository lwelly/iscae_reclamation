class ProfileModel {
  final int id;
  final String? name;
  final String? email;
  final String? matricule;
  final String? phone;
  final String? photo;
  final int? niveauId;
  final String? niveauCode;
  final int? filiereId;
  final String? filiereNom;
  final String? createdAt;
  final String? updatedAt;

  ProfileModel({
    required this.id,
    this.name,
    this.email,
    this.matricule,
    this.phone,
    this.photo,
    this.niveauId,
    this.niveauCode,
    this.filiereId,
    this.filiereNom,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      matricule: json['matricule'],
      phone: json['phone'],
      photo: json['photo'],
      niveauId: json['niveau_id'],
      niveauCode: json['niveau_code'],
      filiereId: json['filiere_id'],
      filiereNom: json['filiere_nom'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'matricule': matricule,
      'phone': phone,
      'photo': photo,
      'niveau_id': niveauId,
      'niveau_code': niveauCode,
      'filiere_id': filiereId,
      'filiere_nom': filiereNom,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
