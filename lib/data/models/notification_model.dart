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
    final data = json['data'] != null ? Map<String, dynamic>.from(json['data']) : null;
    final readAt = json['read_at']?.toString();
    final isRead = readAt != null && readAt.isNotEmpty ||
        json['is_read'] == true ||
        json['is_read'] == 1 ||
        json['is_read'] == '1';

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString(),
      title: json['title']?.toString() ?? data?['title']?.toString() ?? 'Notification',
      body: json['message']?.toString() ?? json['body']?.toString() ?? data?['message']?.toString() ?? '',
      isRead: isRead,
      readAt: readAt,
      channel: json['channel']?.toString(),
      data: data,
      reclamationId: json['reclamation_id']?.toString() ?? data?['reclamation_id']?.toString(),
      sentAt: json['sent_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
    String? readAt,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      channel: channel,
      data: data,
      reclamationId: reclamationId,
      sentAt: sentAt,
      createdAt: createdAt,
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