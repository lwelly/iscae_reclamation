enum ReclamationStatus { submitted, received, in_review, resolved, rejected, escalated }
enum ReclamationType { controle, examen, rattrapage }

class ReclamationModel {
  final int id;
  final String referenceNumber;
  final int studentId;
  final int moduleId;
  final int semestreId;
  final int? noteId;
  final String academicYear;
  final ReclamationType type;
  final double? noteActuelle;
  final double? noteReclamee;
  final String justification;
  final ReclamationStatus status;
  final String? adminResponse;
  final DateTime? meetingScheduledAt;
  final String? meetingLocation;
  final DateTime createdAt;

  ReclamationModel({
    required this.id,
    required this.referenceNumber,
    required this.studentId,
    required this.moduleId,
    required this.semestreId,
    this.noteId,
    required this.academicYear,
    required this.type,
    this.noteActuelle,
    this.noteReclamee,
    required this.justification,
    required this.status,
    this.adminResponse,
    this.meetingScheduledAt,
    this.meetingLocation,
    required this.createdAt,
  });

  // مصنع (Factory) لتحويل الـ JSON القادم من لارفيل إلى Model داخل فلاتر
  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    return ReclamationModel(
      id: json['id'],
      referenceNumber: json['reference_number'],
      studentId: json['student_id'],
      moduleId: json['module_id'],
      semestreId: json['semestre_id'],
      noteId: json['note_id'],
      academicYear: json['academic_year'],
      type: ReclamationType.values.byName(json['type']),
      noteActuelle: json['note_actuelle'] != null ? double.parse(json['note_actuelle'].toString()) : null,
      noteReclamee: json['note_reclamee'] != null ? double.parse(json['note_reclamee'].toString()) : null,
      justification: json['justification'],
      status: ReclamationStatus.values.byName(json['status']),
      adminResponse: json['admin_response'],
      meetingScheduledAt: json['meeting_scheduled_at'] != null ? DateTime.parse(json['meeting_scheduled_at']) : null,
      meetingLocation: json['meeting_location'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // تحويل الكائن إلى Map لإرساله إلى لارفيل عند إنشاء شكوى جديدة
  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'semestre_id': semestreId,
      'note_id': noteId,
      'academic_year': academicYear,
      'type': type.name,
      'note_actuelle': noteActuelle,
      'note_reclamee': noteReclamee,
      'justification': justification,
    };
  }
}