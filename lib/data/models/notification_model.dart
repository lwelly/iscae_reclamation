class NotificationModel {
  final int id;
  final String title;
  final String? message;
  final String? type; // info, warning, success, error
  final bool isRead;
  final String? createdAt;
  final String? readAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    this.message,
    this.type,
    required this.isRead,
    this.createdAt,
    this.readAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
      readAt: json['read_at'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt,
      'read_at': readAt,
      'data': data,
    };
  }
}
