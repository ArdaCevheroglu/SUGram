import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('profile_images').child('$userId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload post image
  Future<String> uploadPostImage(String userId, File imageFile) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      Reference ref = _storage.ref().child('posts').child('$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload message image
  Future<String> uploadMessageImage(String chatId, String userId, File imageFile) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      Reference ref = _storage.ref().child('messages').child(chatId).child('$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload event image
  Future<String> uploadEventImage(String eventId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('events').child('$eventId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Delete file by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }
}