import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Listen to user notifications
  void listenToUserNotifications(String userId) {
    _notificationService.getUserNotifications(userId).listen((notificationsList) {
      _notifications = notificationsList;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);

      // Update notification in list
      for (int i = 0; i < _notifications.length; i++) {
        if (_notifications[i].id == notificationId) {
          _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            triggerUserId: _notifications[i].triggerUserId,
            triggerUsername: _notifications[i].triggerUsername,
            triggerUserProfileImageUrl: _notifications[i].triggerUserProfileImageUrl,
            type: _notifications[i].type,
            postId: _notifications[i].postId,
            commentId: _notifications[i].commentId,
            eventId: _notifications[i].eventId,
            content: _notifications[i].content,
            timestamp: _notifications[i].timestamp,
            isRead: true,
          );
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _notificationService.markAllNotificationsAsRead(userId);

      // Update all notifications in list
      _notifications = _notifications.map((notification) => NotificationModel(
        id: notification.id,
        userId: notification.userId,
        triggerUserId: notification.triggerUserId,
        triggerUsername: notification.triggerUsername,
        triggerUserProfileImageUrl: notification.triggerUserProfileImageUrl,
        type: notification.type,
        postId: notification.postId,
        commentId: notification.commentId,
        eventId: notification.eventId,
        content: notification.content,
        timestamp: notification.timestamp,
        isRead: true,
      )).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Remove from list
      _notifications.removeWhere((notification) => notification.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}