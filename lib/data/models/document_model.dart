class DocumentModel {
  final int id;
  final String titre;
  final String? description;
  final String? type; // pdf, doc, image, etc.
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? category;
  final bool? isVisible;
  final String? createdAt;
  final String? updatedAt;

  DocumentModel({
    required this.id,
    required this.titre,
    this.description,
    this.type,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.category,
    this.isVisible,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      type: json['type'],
      filePath: json['file_path'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      category: json['category'],
      isVisible: json['is_visible'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'type': type,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'category': category,
      'is_visible': isVisible,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
