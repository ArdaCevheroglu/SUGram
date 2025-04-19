import 'package:flutter/material.dart';
import 'dart:io';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  String? _currentChatId;
  UserModel? _chatPartner;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  String? get currentChatId => _currentChatId;
  UserModel? get chatPartner => _chatPartner;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to user's chats
  void listenToUserChats(String userId) {
    _messageService.getUserChats(userId).listen((chatsList) {
      _chats = chatsList;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  // Create or get chat with another user
  Future<String?> createOrGetChat(
      String currentUserId, String targetUserId) async {
    try {
      String chatId = await _messageService.createOrGetChat(
        currentUserId,
        targetUserId,
      );
      _currentChatId = chatId;
      
      // Load chat partner info
      await getChatPartner(targetUserId);
      
      return chatId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get chat partner info
  Future<void> getChatPartner(String userId) async {
    try {
      _chatPartner = await _userService.getUserById(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Listen to messages in a chat
  void listenToChatMessages(String chatId) {
    _currentChatId = chatId;
    _messageService.getChatMessages(chatId).listen((messagesList) {
      _messages = messagesList;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  // Send text message
  Future<bool> sendTextMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _messageService.sendTextMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send image message
  Future<bool> sendImageMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File imageFile,
    String text = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _messageService.sendImageMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        imageFile: imageFile,
        text: text,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forward a post
  Future<bool> forwardPost({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String postId,
    String text = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _messageService.sendPostMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        postId: postId,
        text: text,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _messageService.markMessagesAsRead(chatId, currentUserId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentChatId = null;
    _chatPartner = null;
    _messages = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}