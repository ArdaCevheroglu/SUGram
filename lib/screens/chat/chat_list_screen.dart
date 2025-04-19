import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/message_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import 'chat_screen.dart';
import '../search/search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Map<String, UserModel?> _chatPartners = {};

  @override
  void initState() {
    super.initState();
    _startListeningToChats();
  }

  void _startListeningToChats() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.currentUser != null) {
      Provider.of<MessageViewModel>(context, listen: false)
          .listenToUserChats(authViewModel.currentUser!.id);
    }
  }

  Future<void> _loadChatPartner(String chatId, List<String> participants) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null) {
      // Find the other participant (not the current user)
      final String partnerId = participants.firstWhere(
        (id) => id != authViewModel.currentUser!.id,
        orElse: () => '',
      );
      
      if (partnerId.isNotEmpty) {
        final UserModel? partner = await userViewModel.getUserById(partnerId);
        
        setState(() {
          _chatPartners[chatId] = partner;
        });
      }
    }
  }

  void _navigateToChat(String targetUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(targetUserId: targetUserId),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageViewModel = Provider.of<MessageViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    // Load chat partners that haven't been loaded yet
    for (final chat in messageViewModel.chats) {
      if (!_chatPartners.containsKey(chat.id)) {
        _loadChatPartner(chat.id, chat.participants);
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: messageViewModel.chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 80.0,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Start a conversation with another student',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _navigateToSearch,
                    child: const Text('Find People'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: messageViewModel.chats.length,
              itemBuilder: (context, index) {
                final chat = messageViewModel.chats[index];
                final partner = _chatPartners[chat.id];
                
                if (partner == null) {
                  return const SizedBox.shrink();
                }
                
                final lastMessage = chat.lastMessage;
                final isUnread = !lastMessage.isRead && 
                    lastMessage.receiverId == authViewModel.currentUser?.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: partner.profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(partner.profileImageUrl)
                        : null,
                    child: partner.profileImageUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(
                        partner.username,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (partner.isVerified) ...[
                        const SizedBox(width: 4.0),
                        const Icon(
                          Icons.verified,
                          size: 16.0,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    lastMessage.text.isNotEmpty
                        ? lastMessage.text
                        : lastMessage.imageUrl.isNotEmpty
                            ? 'Sent an image'
                            : lastMessage.postId != null
                                ? 'Shared a post'
                                : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormatter.formatChatMessageTime(lastMessage.timestamp),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isUnread
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      if (isUnread)
                        Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  onTap: () => _navigateToChat(partner.id),
                );
              },
            ),
    );
  }
}