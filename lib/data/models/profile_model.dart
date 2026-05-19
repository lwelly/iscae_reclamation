class ProfileModel {
  final int id;
  final String email;
  final String role;
  final bool isActive;
  final String? lastLoginAt;
  final String? passwordChangedAt;

  // Student data
  final int? studentId;
  final String? matricule;
  final String? nni;
  final String? nom;
  final String? prenom;
  final String? studentEmail;
  final String? phone;
  final String? dateNaissance;
  final String? lieuNaissance;
  final String? nationalite;
  final String? adresse;
  final String? academicYear;
  final String? status;
  final String? photoPath;
  final String? photoUrl;

  // Relations
  final Filiere? filiere;
  final Niveau? niveau;

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.passwordChangedAt,
    this.studentId,
    this.matricule,
    this.nni,
    this.nom,
    this.prenom,
    this.studentEmail,
    this.phone,
    this.dateNaissance,
    this.lieuNaissance,
    this.nationalite,
    this.adresse,
    this.academicYear,
    this.status,
    this.photoPath,
    this.photoUrl,
    this.filiere,
    this.niveau,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawStudent = json['student'];
    final studentData = rawStudent is Map<String, dynamic> ? rawStudent : <String, dynamic>{};
    final rawFiliere = studentData['filiere'];
    final rawNiveau = studentData['niveau'];
    final filiereData = rawFiliere is Map<String, dynamic> ? rawFiliere : null;
    final niveauData = rawNiveau is Map<String, dynamic> ? rawNiveau : null;

    return ProfileModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? true,
      lastLoginAt: json['last_login_at'],
      passwordChangedAt: json['password_changed_at'],
      studentId: studentData['id'],
      matricule: studentData['matricule'],
      nni: studentData['nni'],
      nom: studentData['nom'] ?? studentData['last_name'],
      prenom: studentData['prenom'] ?? studentData['first_name'],
      studentEmail: studentData['email'],
      phone: studentData['phone'],
      dateNaissance: studentData['date_naissance'],
      lieuNaissance: studentData['lieu_naissance'],
      nationalite: studentData['nationalite'],
      adresse: studentData['adresse'],
      academicYear: studentData['academic_year'],
      status: studentData['status'],
      photoPath: studentData['photo_path'],
      photoUrl: studentData['photo_url'],
      filiere: filiereData != null
          ? Filiere.fromJson(filiereData)
          : (studentData['filiere_name'] != null
              ? Filiere(name: studentData['filiere_name']?.toString())
              : null),
      niveau: niveauData != null
          ? Niveau.fromJson(niveauData)
          : (studentData['niveau_label'] != null
              ? Niveau(label: studentData['niveau_label']?.toString())
              : null),
    );
  }

  String get fullName => '${prenom ?? ''} ${nom ?? ''}'.trim();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'is_active': isActive,
      'last_login_at': lastLoginAt,
      'password_changed_at': passwordChangedAt,
      'student': {
        'id': studentId,
        'matricule': matricule,
        'nni': nni,
        'nom': nom,
        'prenom': prenom,
        'email': studentEmail,
        'phone': phone,
        'date_naissance': dateNaissance,
        'lieu_naissance': lieuNaissance,
        'nationalite': nationalite,
        'adresse': adresse,
        'academic_year': academicYear,
        'status': status,
        'photo_path': photoPath,
        'photo_url': photoUrl,
        'filiere': filiere?.toJson(),
        'niveau': niveau?.toJson(),
      },
    };
  }
}

class Filiere {
  final String? name;
  final String? code;

  Filiere({this.name, this.code});

  factory Filiere.fromJson(Map<String, dynamic> json) {
    return Filiere(
      name: json['name'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }
}

class Niveau {
  final String? code;
  final String? label;

  Niveau({this.code, this.label});

  factory Niveau.fromJson(Map<String, dynamic> json) {
    return Niveau(
      code: json['code'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
    };
  }
}
