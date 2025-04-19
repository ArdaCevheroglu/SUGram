import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String? postId; // For forwarded posts

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.imageUrl = '',
    required this.timestamp,
    this.isRead = false,
    this.postId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      postId: json['postId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'postId': postId,
    };
  }
}

class ChatModel {
  final String id;
  final List<String> participants;
  final MessageModel lastMessage;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: MessageModel.fromJson(json['lastMessage'] ?? {}),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage.toJson(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}