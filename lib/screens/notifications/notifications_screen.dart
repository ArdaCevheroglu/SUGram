import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../profile/profile_screen.dart';
import '../post/post_detail_screen.dart';
import '../events/event_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _startListeningToNotifications();
  }

  void _startListeningToNotifications() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.currentUser != null) {
      Provider.of<NotificationViewModel>(context, listen: false)
          .listenToUserNotifications(authViewModel.currentUser!.id);
    }
  }

  Future<void> _markAllAsRead() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.currentUser != null) {
      Provider.of<NotificationViewModel>(context, listen: false)
          .markAllNotificationsAsRead(authViewModel.currentUser!.id);
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark notification as read
    Provider.of<NotificationViewModel>(context, listen: false)
        .markNotificationAsRead(notification.id);
    
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.mention:
        if (notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: notification.postId!),
            ),
          );
        }
        break;
      case NotificationType.follow:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: notification.triggerUserId),
          ),
        );
        break;
      case NotificationType.eventReminder:
      case NotificationType.announcement:
        if (notification.eventId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventId: notification.eventId!),
            ),
          );
        }
        break;
      case NotificationType.message:
        // Navigate to chat screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationViewModel = Provider.of<NotificationViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationViewModel.unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notificationViewModel.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 80.0,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'When you get notifications, they\'ll appear here',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notificationViewModel.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationViewModel.notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final bool isUnread = !notification.isRead;
    
    // Get notification icon based on type
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.like:
        iconData = Icons.favorite;
        iconColor = AppTheme.secondaryColor;
        break;
      case NotificationType.comment:
        iconData = Icons.comment;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.follow:
        iconData = Icons.person_add;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.message:
        iconData = Icons.chat_bubble;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.eventReminder:
        iconData = Icons.event;
        iconColor = Colors.orange;
        break;
      case NotificationType.announcement:
        iconData = Icons.campaign;
        iconColor = Colors.purple;
        break;
      case NotificationType.mention:
        iconData = Icons.alternate_email;
        iconColor = AppTheme.primaryColor;
        break;
    }
    
    return ListTile(
      leading: notification.triggerUserProfileImageUrl.isNotEmpty
          ? CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                notification.triggerUserProfileImageUrl,
              ),
            )
          : CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(
                iconData,
                color: iconColor,
              ),
            ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 14.0,
          ),
          children: [
            TextSpan(
              text: notification.triggerUsername,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' ${notification.content}',
            ),
          ],
        ),
      ),
      subtitle: Text(
        DateFormatter.formatTimeAgo(notification.timestamp),
        style: const TextStyle(
          fontSize: 12.0,
          color: AppTheme.secondaryTextColor,
        ),
      ),
      trailing: isUnread
          ? Container(
              width: 10.0,
              height: 10.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
            )
          : null,
      tileColor: isUnread ? AppTheme.primaryColor.withOpacity(0.05) : null,
      onTap: () => _handleNotificationTap(notification),
    );
  }
}