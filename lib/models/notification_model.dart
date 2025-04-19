import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  comment,
  follow,
  message,
  eventReminder,
  announcement,
  mention,
}

class NotificationModel {
  final String id;
  final String userId; // User who will receive the notification
  final String triggerUserId; // User who triggered the notification
  final String triggerUsername;
  final String triggerUserProfileImageUrl;
  final NotificationType type;
  final String? postId;
  final String? commentId;
  final String? eventId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.triggerUserId,
    required this.triggerUsername,
    required this.triggerUserProfileImageUrl,
    required this.type,
    this.postId,
    this.commentId,
    this.eventId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      triggerUserId: json['triggerUserId'] ?? '',
      triggerUsername: json['triggerUsername'] ?? '',
      triggerUserProfileImageUrl: json['triggerUserProfileImageUrl'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.like,
      ),
      postId: json['postId'],
      commentId: json['commentId'],
      eventId: json['eventId'],
      content: json['content'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'triggerUserId': triggerUserId,
      'triggerUsername': triggerUsername,
      'triggerUserProfileImageUrl': triggerUserProfileImageUrl,
      'type': type.toString().split('.').last,
      'postId': postId,
      'commentId': commentId,
      'eventId': eventId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}