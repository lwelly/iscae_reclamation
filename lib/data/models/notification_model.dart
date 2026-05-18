class NotificationModel {
  final String id;
  final String? type;
  final String title;
  final String body;
  final bool isRead;
  final String? readAt;
  final String? channel;
  final Map<String, dynamic>? data;
  final String? reclamationId;
  final String? sentAt;
  final String? createdAt;

  NotificationModel({
    required this.id,
    this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.readAt,
    this.channel,
    this.data,
    this.reclamationId,
    this.sentAt,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString(),
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? json['message'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      readAt: json['read_at']?.toString(),
      channel: json['channel']?.toString(),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      reclamationId: json['reclamation_id']?.toString(),
      sentAt: json['sent_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'read_at': readAt,
      'channel': channel,
      'data': data,
      'reclamation_id': reclamationId,
      'sent_at': sentAt,
      'created_at': createdAt,
    };
  }
}