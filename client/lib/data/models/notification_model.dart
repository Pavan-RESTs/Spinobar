class NotificationModel {
  final String id;
  final String categoryId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? actionData;

  NotificationModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.actionData,
  });

  NotificationModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionData: actionData ?? this.actionData,
    );
  }
}
