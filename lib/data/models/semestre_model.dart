class SemestreModel {
  final int id;
  final String code;
  final String label;
  final String academicYear;
  final bool isOpen;
  final bool isExamOpen;
  final bool isRattrapageOpen;
  final List<String> availableTypes;
  final String? openAt;
  final String? closeAt;
  final String? examOpenAt;
  final String? examCloseAt;
  final String? rattrapageOpenAt;
  final String? rattrapageCloseAt;
  final String createdAt;

  SemestreModel({
    required this.id,
    required this.code,
    required this.label,
    required this.academicYear,
    required this.isOpen,
    required this.isExamOpen,
    required this.isRattrapageOpen,
    required this.availableTypes,
    this.openAt,
    this.closeAt,
    this.examOpenAt,
    this.examCloseAt,
    this.rattrapageOpenAt,
    this.rattrapageCloseAt,
    required this.createdAt,
  });

  factory SemestreModel.fromJson(Map<String, dynamic> json) {
    List<String> types = [];
    if (json['is_open'] == true) types.add('cc');
    if (json['is_exam_open'] == true) types.add('examen');
    if (json['is_rattrapage_open'] == true) types.add('rattrapage');

    return SemestreModel(
      id: json['id'],
      code: json['code'],
      label: json['label'],
      academicYear: json['academic_year'],
      isOpen: json['is_open'] ?? false,
      isExamOpen: json['is_exam_open'] ?? false,
      isRattrapageOpen: json['is_rattrapage_open'] ?? false,
      availableTypes: json['available_types'] != null 
          ? List<String>.from(json['available_types']) 
          : types,
      openAt: json['open_at'],
      closeAt: json['close_at'],
      examOpenAt: json['exam_open_at'],
      examCloseAt: json['exam_close_at'],
      rattrapageOpenAt: json['rattrapage_open_at'],
      rattrapageCloseAt: json['rattrapage_close_at'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'label': label,
      'academic_year': academicYear,
      'is_open': isOpen,
      'is_exam_open': isExamOpen,
      'is_rattrapage_open': isRattrapageOpen,
      'available_types': availableTypes,
      'open_at': openAt,
      'close_at': closeAt,
      'exam_open_at': examOpenAt,
      'exam_close_at': examCloseAt,
      'rattrapage_open_at': rattrapageOpenAt,
      'rattrapage_close_at': rattrapageCloseAt,
      'created_at': createdAt,
    };
  }
}
