import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create or get chat between two users
  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      // Sort user IDs to ensure consistent chat ID creation
      List<String> sortedUserIds = [userId1, userId2]..sort();
      String chatId = '${sortedUserIds[0]}_${sortedUserIds[1]}';

      // Check if chat already exists
      DocumentSnapshot chatSnapshot =
          await _firestore.collection('chats').doc(chatId).get();

      if (!chatSnapshot.exists) {
        // Create new chat
        await _firestore.collection('chats').doc(chatId).set({
          'id': chatId,
          'participants': sortedUserIds,
          'updatedAt': Timestamp.now(),
          'lastMessage': {
            'id': '',
            'senderId': '',
            'receiverId': '',
            'text': '',
            'imageUrl': '',
            'timestamp': Timestamp.now(),
            'isRead': false,
          },
        });
      }

      return chatId;
    } catch (e) {
      rethrow;
    }
  }

  // Send text message
  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      // Create message document reference
      DocumentReference messageRef =
          _firestore.collection('chats').doc(chatId).collection('messages').doc();

      // Create message object
      MessageModel message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        timestamp: DateTime.now(),
      );

      // Save message to Firestore
      await messageRef.set(message.toJson());

      // Update chat with last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.toJson(),
        'updatedAt': Timestamp.fromDate(message.timestamp),
      });

      return message;
    } catch (e) {
      rethrow;
    }
  }

  // Send image message
  Future<MessageModel> sendImageMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File imageFile,
    String text = '',
  }) async {
    try {
      // Upload image to Firebase Storage
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_$senderId';
      Reference storageRef =
          _storage.ref().child('messages').child('$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Create message document reference
      DocumentReference messageRef =
          _firestore.collection('chats').doc(chatId).collection('messages').doc();

      // Create message object
      MessageModel message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      // Save message to Firestore
      await messageRef.set(message.toJson());

      // Update chat with last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.toJson(),
        'updatedAt': Timestamp.fromDate(message.timestamp),
      });

      return message;
    } catch (e) {
      rethrow;
    }
  }

  // Send post message (forwarding a post)
  Future<MessageModel> sendPostMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String postId,
    String text = '',
  }) async {
    try {
      // Create message document reference
      DocumentReference messageRef =
          _firestore.collection('chats').doc(chatId).collection('messages').doc();

      // Create message object
      MessageModel message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        timestamp: DateTime.now(),
        postId: postId,
      );

      // Save message to Firestore
      await messageRef.set(message.toJson());

      // Update chat with last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.toJson(),
        'updatedAt': Timestamp.fromDate(message.timestamp),
      });

      return message;
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList());
  }

  // Get user chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromJson(doc.data()))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String chatId, String currentUserId) async {
    try {
      // Get unread messages sent to currentUser
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Update each message to mark as read
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Update last message if it's unread
      DocumentSnapshot chatSnapshot =
          await _firestore.collection('chats').doc(chatId).get();
      
      Map<String, dynamic> chatData = chatSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> lastMessage = chatData['lastMessage'];

      if (lastMessage['receiverId'] == currentUserId &&
          !lastMessage['isRead']) {
        lastMessage['isRead'] = true;
        await _firestore
            .collection('chats')
            .doc(chatId)
            .update({'lastMessage': lastMessage});
      }
    } catch (e) {
      rethrow;
    }
  }
}