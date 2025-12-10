// lib/data/services/notification_service.dart
import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // ---------- New helpers ----------
  NotificationModel? getById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new notification with a provided ID.
  /// If a notification with same ID exists and is unread, it will NOT create a duplicate.
  /// If it exists and is read, this will mark it unread and update content.
  void addNotificationWithId({
    required String id,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    String? actionData,
  }) {
    final existingIndex = _notifications.indexWhere((n) => n.id == id);

    if (existingIndex != -1) {
      // If it exists and is unread -> update content but do not bump unreadCount
      final existing = _notifications[existingIndex];
      final wasRead = existing.isRead;
      _notifications[existingIndex] = existing.copyWith(
        title: title,
        message: message,
        type: type,
        priority: priority,
        isRead: false,
        actionData: actionData,
        timestamp: DateTime.now(),
      );
      if (wasRead) {
        _unreadCount++;
      }
      notifyListeners();
      return;
    }

    final notification = NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      actionData: actionData,
      priority: priority,
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  /// Upsert/update an existing notification. If it doesn't exist, create it.
  /// Important: if the existing notification is unread, keep it unread and don't double-increment unreadCount.
  void upsertNotification({
    required String id,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    String? actionData,
  }) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final existing = _notifications[idx];
      final wasRead = existing.isRead;
      _notifications[idx] = existing.copyWith(
        title: title,
        message: message,
        type: type,
        priority: priority,
        isRead: existing.isRead,
        actionData: actionData ?? existing.actionData,
        timestamp: DateTime.now(),
      );
      // if it was read and we want to bring it as new alert, mark unread
      if (wasRead == true) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: false);
        _unreadCount++;
      }
      notifyListeners();
    } else {
      // create new
      addNotificationWithId(
        id: id,
        title: title,
        message: message,
        type: type,
        priority: priority,
        actionData: actionData,
      );
    }
  }

  // Mark a notification as read (keeps history) — user chose option B
  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (!_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  // Delete a notification
  void deleteNotification(String id) {
    final notification = _notifications.firstWhere((n) => n.id == id,
        orElse: () => throw Exception("Notification not found"));
    if (!notification.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Clear all notifications (history)
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  // Clear read notifications from history
  void clearRead() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get notifications by priority
  List<NotificationModel> getNotificationsByPriority(
      NotificationPriority priority,
      ) {
    return _notifications.where((n) => n.priority == priority).toList();
  }
}
