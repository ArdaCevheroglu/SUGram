import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new post
  Future<PostModel> createPost({
    required String userId,
    required String username,
    required String userProfileImageUrl,
    required File imageFile,
    String caption = '',
    String location = '',
  }) async {
    try {
      // Upload image to Firebase Storage
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      Reference storageRef =
          _storage.ref().child('posts').child('$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Create post document reference
      DocumentReference postRef = _firestore.collection('posts').doc();

      // Create post object
      PostModel post = PostModel(
        id: postRef.id,
        userId: userId,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        imageUrl: imageUrl,
        caption: caption,
        createdAt: DateTime.now(),
        location: location,
      );

      // Save post to Firestore
      await postRef.set(post.toJson());

      return post;
    } catch (e) {
      rethrow;
    }
  }

  // Get posts for feed (from followed users)
  Future<List<PostModel>> getFeedPosts(UserModel currentUser) async {
    try {
      // Get posts from users that current user follows
      QuerySnapshot postSnapshot = await _firestore
          .collection('posts')
          .where('userId', whereIn: [
            ...currentUser.following,
            currentUser.id
          ]) // Include current user's posts
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      List<PostModel> posts = postSnapshot.docs
          .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return posts;
    } catch (e) {
      rethrow;
    }
  }

  // Get user posts
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      QuerySnapshot postSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<PostModel> posts = postSnapshot.docs
          .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return posts;
    } catch (e) {
      rethrow;
    }
  }

  // Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      DocumentSnapshot postSnapshot =
          await _firestore.collection('posts').doc(postId).get();

      if (!postSnapshot.exists) return null;

      return PostModel.fromJson(
          postSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Add a comment to a post
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String username,
    required String userProfileImageUrl,
    required String text,
  }) async {
    try {
      // Create comment ID
      String commentId = _firestore.collection('comments').doc().id;

      // Create comment object
      CommentModel comment = CommentModel(
        id: commentId,
        userId: userId,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        text: text,
        createdAt: DateTime.now(),
      );

      // Add comment to post document
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toJson()])
      });

      return comment;
    } catch (e) {
      rethrow;
    }
  }

  // Like a comment
  Future<void> likeComment(
      String postId, String commentId, String userId) async {
    try {
      // Get the post document
      DocumentSnapshot postSnapshot =
          await _firestore.collection('posts').doc(postId).get();

      // Convert to PostModel
      PostModel post =
          PostModel.fromJson(postSnapshot.data() as Map<String, dynamic>);

      // Find and update the comment
      List<CommentModel> updatedComments = post.comments.map((comment) {
        if (comment.id == commentId) {
          List<String> updatedLikes = List.from(comment.likes);
          if (!updatedLikes.contains(userId)) {
            updatedLikes.add(userId);
          }
          return CommentModel(
            id: comment.id,
            userId: comment.userId,
            username: comment.username,
            userProfileImageUrl: comment.userProfileImageUrl,
            text: comment.text,
            likes: updatedLikes,
            createdAt: comment.createdAt,
          );
        }
        return comment;
      }).toList();

      // Update the post with modified comments
      await _firestore.collection('posts').doc(postId).update({
        'comments': updatedComments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unlike a comment
  Future<void> unlikeComment(
      String postId, String commentId, String userId) async {
    try {
      // Get the post document
      DocumentSnapshot postSnapshot =
          await _firestore.collection('posts').doc(postId).get();

      // Convert to PostModel
      PostModel post =
          PostModel.fromJson(postSnapshot.data() as Map<String, dynamic>);

      // Find and update the comment
      List<CommentModel> updatedComments = post.comments.map((comment) {
        if (comment.id == commentId) {
          List<String> updatedLikes = List.from(comment.likes);
          updatedLikes.remove(userId);
          return CommentModel(
            id: comment.id,
            userId: comment.userId,
            username: comment.username,
            userProfileImageUrl: comment.userProfileImageUrl,
            text: comment.text,
            likes: updatedLikes,
            createdAt: comment.createdAt,
          );
        }
        return comment;
      }).toList();

      // Update the post with modified comments
      await _firestore.collection('posts').doc(postId).update({
        'comments': updatedComments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Get the post to access the image URL
      DocumentSnapshot postSnapshot =
          await _firestore.collection('posts').doc(postId).get();
      
      if (!postSnapshot.exists) return;

      PostModel post =
          PostModel.fromJson(postSnapshot.data() as Map<String, dynamic>);

      // Delete post document from Firestore
      await _firestore.collection('posts').doc(postId).delete();

      // Delete post image from Storage if it exists
      if (post.imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(post.imageUrl).delete();
        } catch (e) {
          // Ignore if image doesn't exist
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}