import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a like notification
  Future<void> createLikeNotification({
    required String userId,
    required UserModel triggerUser,
    required String postId,
  }) async {
    try {
      // Don't create notification if user is liking their own post
      if (userId == triggerUser.id) return;

      // Check if notification already exists
      QuerySnapshot existingNotification = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('triggerUserId', isEqualTo: triggerUser.id)
          .where('type', isEqualTo: NotificationType.like.toString().split('.').last)
          .where('postId', isEqualTo: postId)
          .get();

      if (existingNotification.docs.isNotEmpty) {
        // Update existing notification
        await _firestore
            .collection('notifications')
            .doc(existingNotification.docs.first.id)
            .update({
          'timestamp': Timestamp.now(),
          'isRead': false,
        });
        return;
      }

      // Create notification document reference
      DocumentReference notificationRef =
          _firestore.collection('notifications').doc();

      // Create notification object
      NotificationModel notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        triggerUserId: triggerUser.id,
        triggerUsername: triggerUser.username,
        triggerUserProfileImageUrl: triggerUser.profileImageUrl,
        type: NotificationType.like,
        postId: postId,
        content: 'liked your post',
        timestamp: DateTime.now(),
      );

      // Save notification to Firestore
      await notificationRef.set(notification.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Create a comment notification
  Future<void> createCommentNotification({
    required String userId,
    required UserModel triggerUser,
    required String postId,
    required String commentId,
    required String commentText,
  }) async {
    try {
      // Don't create notification if user is commenting on their own post
      if (userId == triggerUser.id) return;

      // Create notification document reference
      DocumentReference notificationRef =
          _firestore.collection('notifications').doc();

      // Create notification object
      NotificationModel notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        triggerUserId: triggerUser.id,
        triggerUsername: triggerUser.username,
        triggerUserProfileImageUrl: triggerUser.profileImageUrl,
        type: NotificationType.comment,
        postId: postId,
        commentId: commentId,
        content: 'commented: ${commentText.length > 30 ? '${commentText.substring(0, 30)}...' : commentText}',
        timestamp: DateTime.now(),
      );

      // Save notification to Firestore
      await notificationRef.set(notification.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Create a follow notification
  Future<void> createFollowNotification({
    required String userId,
    required UserModel triggerUser,
  }) async {
    try {
      // Create notification document reference
      DocumentReference notificationRef =
          _firestore.collection('notifications').doc();

      // Create notification object
      NotificationModel notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        triggerUserId: triggerUser.id,
        triggerUsername: triggerUser.username,
        triggerUserProfileImageUrl: triggerUser.profileImageUrl,
        type: NotificationType.follow,
        content: 'started following you',
        timestamp: DateTime.now(),
      );

      // Save notification to Firestore
      await notificationRef.set(notification.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Create an event reminder notification
  Future<void> createEventReminderNotification({
    required String userId,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      // Create notification document reference
      DocumentReference notificationRef =
          _firestore.collection('notifications').doc();

      // Create notification object
      NotificationModel notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        triggerUserId: '',
        triggerUsername: 'SUGram',
        triggerUserProfileImageUrl: '',
        type: NotificationType.eventReminder,
        eventId: eventId,
        content: 'Event reminder: $eventTitle',
        timestamp: DateTime.now(),
      );

      // Save notification to Firestore
      await notificationRef.set(notification.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Create an announcement notification
  Future<void> createAnnouncementNotification({
    required List<String> userIds,
    required String content,
  }) async {
    try {
      // Create batch write
      WriteBatch batch = _firestore.batch();

      for (String userId in userIds) {
        // Create notification document reference
        DocumentReference notificationRef =
            _firestore.collection('notifications').doc();

        // Create notification object
        NotificationModel notification = NotificationModel(
          id: notificationRef.id,
          userId: userId,
          triggerUserId: '',
          triggerUsername: 'SUGram',
          triggerUserProfileImageUrl: '',
          type: NotificationType.announcement,
          content: content,
          timestamp: DateTime.now(),
        );

        // Add to batch
        batch.set(notificationRef, notification.toJson());
      }

      // Commit batch
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Create a mention notification
  Future<void> createMentionNotification({
    required String userId,
    required UserModel triggerUser,
    required String postId,
    String? commentId,
  }) async {
    try {
      // Don't create notification if user is mentioning themselves
      if (userId == triggerUser.id) return;

      // Create notification document reference
      DocumentReference notificationRef =
          _firestore.collection('notifications').doc();

      // Create notification object
      NotificationModel notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        triggerUserId: triggerUser.id,
        triggerUsername: triggerUser.username,
        triggerUserProfileImageUrl: triggerUser.profileImageUrl,
        type: NotificationType.mention,
        postId: postId,
        commentId: commentId,
        content: 'mentioned you in a ${commentId != null ? 'comment' : 'post'}',
        timestamp: DateTime.now(),
      );

      // Save notification to Firestore
      await notificationRef.set(notification.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      // Get all unread notifications
      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Update each notification to mark as read
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }
}