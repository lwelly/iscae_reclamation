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

  bool get hasPhoto =>
      (photoUrl != null && photoUrl!.isNotEmpty) || (photoPath != null && photoPath!.isNotEmpty);

  /// Conserve la photo si le rechargement API ne la renvoie pas.
  ProfileModel mergePhotoFrom(ProfileModel? other) {
    if (other == null || !other.hasPhoto) return this;
    if (hasPhoto) return this;
    return withPhotoFrom(other);
  }

  /// Remplace la photo par celle de [other] (ex. réponse upload).
  ProfileModel withPhotoFrom(ProfileModel? other) {
    if (other == null || !other.hasPhoto) return this;
    return copyWith(photoUrl: other.photoUrl, photoPath: other.photoPath);
  }

  ProfileModel copyWith({
    String? photoUrl,
    String? photoPath,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      role: role,
      isActive: isActive,
      lastLoginAt: lastLoginAt,
      passwordChangedAt: passwordChangedAt,
      studentId: studentId,
      matricule: matricule,
      nni: nni,
      nom: nom,
      prenom: prenom,
      studentEmail: studentEmail,
      phone: phone,
      dateNaissance: dateNaissance,
      lieuNaissance: lieuNaissance,
      nationalite: nationalite,
      adresse: adresse,
      academicYear: academicYear,
      status: status,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      filiere: filiere,
      niveau: niveau,
    );
  }

  static String? _firstNonEmpty(List<Map<String, dynamic>> sources, List<String> keys) {
    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    return null;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Réponse « student » seule (souvent après upload photo)
    final isStudentRoot = json.containsKey('matricule') &&
        !json.containsKey('student') &&
        !json.containsKey('role');

    final Map<String, dynamic> userData;
    final Map<String, dynamic> studentData;

    if (isStudentRoot) {
      userData = json;
      studentData = json;
    } else {
      userData = json;
      final rawStudent = json['student'];
      studentData = rawStudent is Map<String, dynamic> ? rawStudent : <String, dynamic>{};
    }

    final maps = [studentData, userData];
    final photoUrl = _firstNonEmpty(maps, [
      'photo_url',
      'photoUrl',
      'avatar_url',
      'profile_photo_url',
    ]);
    final photoPath = _firstNonEmpty(maps, [
      'photo_path',
      'photoPath',
      'photo',
      'avatar',
    ]);

    final rawFiliere = studentData['filiere'];
    final rawNiveau = studentData['niveau'];
    final filiereData = rawFiliere is Map<String, dynamic> ? rawFiliere : null;
    final niveauData = rawNiveau is Map<String, dynamic> ? rawNiveau : null;

    return ProfileModel(
      id: userData['id'] ?? userData['user_id'] ?? 0,
      email: userData['email']?.toString() ?? studentData['email']?.toString() ?? '',
      role: userData['role']?.toString() ?? 'student',
      isActive: userData['is_active'] ?? true,
      lastLoginAt: userData['last_login_at']?.toString(),
      passwordChangedAt: userData['password_changed_at']?.toString(),
      studentId: studentData['id'],
      matricule: studentData['matricule']?.toString(),
      nni: studentData['nni']?.toString(),
      nom: studentData['nom']?.toString() ?? studentData['last_name']?.toString(),
      prenom: studentData['prenom']?.toString() ?? studentData['first_name']?.toString(),
      studentEmail: studentData['email']?.toString(),
      phone: studentData['phone']?.toString(),
      dateNaissance: studentData['date_naissance']?.toString(),
      lieuNaissance: studentData['lieu_naissance']?.toString(),
      nationalite: studentData['nationalite']?.toString(),
      adresse: studentData['adresse']?.toString(),
      academicYear: studentData['academic_year']?.toString(),
      status: studentData['status']?.toString(),
      photoPath: photoPath,
      photoUrl: photoUrl,
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
