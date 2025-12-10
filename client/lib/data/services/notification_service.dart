import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  final Set<String> _activeCategoryLocks = {};

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  void addNotification({
    required String categoryId,
    required String title,
    required String message,
    String? actionData,
  }) {
    if (_activeCategoryLocks.contains(categoryId)) return;

    _activeCategoryLocks.add(categoryId);

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: categoryId,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      actionData: actionData,
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      final categoryId = _notifications[index].categoryId;
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);

      _activeCategoryLocks.remove(categoryId);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    _activeCategoryLocks.clear();
    notifyListeners();
  }

  void deleteNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final notification = _notifications[index];
    if (!notification.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
    _activeCategoryLocks.remove(notification.categoryId);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    _activeCategoryLocks.clear();
    notifyListeners();
  }

  void clearRead() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  bool isCategoryLocked(String categoryId) =>
      _activeCategoryLocks.contains(categoryId);
}
