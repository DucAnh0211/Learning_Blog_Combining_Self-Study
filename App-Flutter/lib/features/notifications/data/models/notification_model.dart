class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final String? targetId;
  final String? actorId;
  final String? actorName;
  final String? actorAvatar;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.targetId,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      targetId: json['targetId'],
      actorId: json['actorId'],
      actorName: json['actorName'] ?? json['actor']?['name'],
      actorAvatar: json['actorAvatar'] ?? json['actor']?['avatarUrl'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
