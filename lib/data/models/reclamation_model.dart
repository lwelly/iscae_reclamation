class ReclamationModel {
  final String id;
  final String referenceNumber;
  final String type;
  final String typeDb;
  final String status;
  final double noteActuelle;
  final double? noteReclamee;
  final String justification;
  final String? adminResponse;
  final bool isEscalated;
  final String? escalationReason;
  final String academicYear;
  final String createdAt;
  final String updatedAt;
  final String? resolvedAt;
  final String? respondedAt;
  final String? escalatedAt;
  final Map<String, dynamic>? meeting;
  final ReclamationModule module;
  final ReclamationSemestre semestre;
  final List<ReclamationAttachment> attachments;
  final List<ReclamationHistory> history;

  ReclamationModel({
    required this.id,
    required this.referenceNumber,
    required this.type,
    required this.typeDb,
    required this.status,
    required this.noteActuelle,
    this.noteReclamee,
    required this.justification,
    this.adminResponse,
    required this.isEscalated,
    this.escalationReason,
    required this.academicYear,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.respondedAt,
    this.escalatedAt,
    this.meeting,
    required this.module,
    required this.semestre,
    this.attachments = const [],
    this.history = const [],
  });

  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    return ReclamationModel(
      id: json['id']?.toString() ?? '',
      referenceNumber: json['reference_number'] ?? json['reference'] ?? '',
      type: json['type'] ?? '',
      typeDb: json['type_db'] ?? '',
      status: json['status'] ?? '',

      // CORRIGÉ : Conversion sécurisée au cas où Laravel envoie un String ("13.00") ou un num (13.0)
      noteActuelle: json['note_actuelle'] != null
          ? (double.tryParse(json['note_actuelle'].toString()) ?? 0.0)
          : 0.0,

      // CORRIGÉ : Conversion sécurisée identique pour la note réclamée
      noteReclamee: json['note_reclamee'] != null
          ? double.tryParse(json['note_reclamee'].toString())
          : null,

      justification: json['justification'] ?? '',
      adminResponse: json['admin_response'],
      isEscalated: json['is_escalated'] ?? false,
      escalationReason: json['escalation_reason'],
      academicYear: json['academic_year'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      resolvedAt: json['resolved_at'],
      respondedAt: json['responded_at'],
      escalatedAt: json['escalated_at'],
      meeting: json['meeting'],
      module: ReclamationModule.fromJson(json['module'] ?? {}),
      semestre: ReclamationSemestre.fromJson(json['semestre'] ?? {}),
      attachments: (json['attachments'] as List?)
          ?.map((e) => ReclamationAttachment.fromJson(e))
          .toList() ?? [],
      history: (json['history'] as List?)
          ?.map((e) => ReclamationHistory.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ReclamationModule {
  final String id;
  final String code;
  final String name;
  final String? coefficient;
  final String? credits;

  ReclamationModule({
    required this.id,
    required this.code,
    required this.name,
    this.coefficient,
    this.credits,
  });

  factory ReclamationModule.fromJson(Map<String, dynamic> json) {
    return ReclamationModule(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      coefficient: json['coefficient']?.toString(),
      credits: json['credits']?.toString(),
    );
  }
}

class ReclamationSemestre {
  final String id;
  final String code;
  final String label;
  final bool isOpen;
  final String? academicYear;

  ReclamationSemestre({
    required this.id,
    required this.code,
    required this.label,
    required this.isOpen,
    this.academicYear,
  });

  factory ReclamationSemestre.fromJson(Map<String, dynamic> json) {
    return ReclamationSemestre(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      label: json['label'] ?? '',
      isOpen: json['is_open'] ?? false,
      academicYear: json['academic_year']?.toString(),
    );
  }
}

class ReclamationAttachment {
  final String id;
  final String fileName;
  final String? filePath;
  final int? fileSize;
  final String? mimeType;
  final String? url;
  final String? createdAt;

  ReclamationAttachment({
    required this.id,
    required this.fileName,
    this.filePath,
    this.fileSize,
    this.mimeType,
    this.url,
    this.createdAt,
  });

  factory ReclamationAttachment.fromJson(Map<String, dynamic> json) {
    return ReclamationAttachment(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name'] ?? 'Fichier',
      filePath: json['file_path'],
      fileSize: json['file_size'] != null ? int.tryParse(json['file_size'].toString()) : null,
      mimeType: json['mime_type'],
      url: json['url'],
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ReclamationHistory {
  final String id;
  final String? oldStatus;
  final String newStatus;
  final String? comment;
  final String createdAt;
  final String changedByLabel;

  ReclamationHistory({
    required this.id,
    this.oldStatus,
    required this.newStatus,
    this.comment,
    required this.createdAt,
    required this.changedByLabel,
  });

  factory ReclamationHistory.fromJson(Map<String, dynamic> json) {
    return ReclamationHistory(
      id: json['id']?.toString() ?? '',
      oldStatus: json['old_status'],
      newStatus: json['new_status'] ?? '',
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
      changedByLabel: json['changed_by_label'] ?? 'Système',
    );
  }
}