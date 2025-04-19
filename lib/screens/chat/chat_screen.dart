import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../view_models/message_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/message_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../profile/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String targetUserId;

  const ChatScreen({super.key, required this.targetUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    Provider.of<MessageViewModel>(context, listen: false).clearCurrentChat();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      // Create or get chat with the target user
      final chatId = await messageViewModel.createOrGetChat(
        authViewModel.currentUser!.id,
        widget.targetUserId,
      );

      if (chatId != null) {
        // Start listening to messages
        messageViewModel.listenToChatMessages(chatId);
        
        // Mark messages as read
        messageViewModel.markMessagesAsRead(chatId, authViewModel.currentUser!.id);

        setState(() {
          _chatId = chatId;
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      await messageViewModel.sendTextMessage(
        chatId: _chatId!,
        senderId: authViewModel.currentUser!.id,
        receiverId: widget.targetUserId,
        text: _messageController.text.trim(),
      );

      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendImage() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);

    if (authViewModel.currentUser != null && _chatId != null) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          File imageFile = File(pickedFile.path);
          
          await messageViewModel.sendImageMessage(
            chatId: _chatId!,
            senderId: authViewModel.currentUser!.id,
            receiverId: widget.targetUserId,
            imageFile: imageFile,
          );

          _scrollToBottom();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.targetUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageViewModel = Provider.of<MessageViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _navigateToUserProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16.0,
                backgroundColor: Colors.grey[300],
                backgroundImage: messageViewModel.chatPartner?.profileImageUrl.isNotEmpty ?? false
                    ? CachedNetworkImageProvider(messageViewModel.chatPartner!.profileImageUrl)
                    : null,
                child: messageViewModel.chatPartner?.profileImageUrl.isEmpty ?? true
                    ? const Icon(
                        Icons.person,
                        size: 16.0,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    messageViewModel.chatPartner?.username ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    messageViewModel.chatPartner?.isVerified ?? false ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: messageViewModel.chatPartner?.isVerified ?? false
                          ? Colors.green
                          : AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _navigateToUserProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messageViewModel.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 60.0,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Say hello to ${messageViewModel.chatPartner?.username ?? 'User'}!',
                          style: const TextStyle(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: messageViewModel.messages.length,
                    itemBuilder: (context, index) {
                      final message = messageViewModel.messages[index];
                      final bool isMe = message.senderId == authViewModel.currentUser?.id;
                      
                      // Group messages by date
                      bool showDate = false;
                      if (index == messageViewModel.messages.length - 1) {
                        showDate = true;
                      } else {
                        final DateTime messageDate = DateTime(
                          message.timestamp.year,
                          message.timestamp.month,
                          message.timestamp.day,
                        );
                        final DateTime prevMessageDate = DateTime(
                          messageViewModel.messages[index + 1].timestamp.year,
                          messageViewModel.messages[index + 1].timestamp.month,
                          messageViewModel.messages[index + 1].timestamp.day,
                        );
                        
                        if (messageDate != prevMessageDate) {
                          showDate = true;
                        }
                      }
                      
                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Text(
                                    DateFormatter.formatDate(message.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24.0)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF0F2F5),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AppTheme.primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image message
            if (message.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    height: 150.0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => const SizedBox(
                    height: 150.0,
                    child: Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            
            // Text message
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(
                right: 8.0,
                left: 8.0,
                bottom: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormatter.formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4.0),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14.0,
                      color: message.isRead ? Colors.white70 : Colors.white54,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}