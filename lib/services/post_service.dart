import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostException implements Exception {
  final String code;
  final String message;

  PostException(this.code, this.message);

  @override
  String toString() => message;
}

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get posts collection reference
  CollectionReference<Map<String, dynamic>> get _postsCollection => 
      _firestore.collection('posts');
      
  // Get comments collection reference
  CollectionReference<Map<String, dynamic>> get _commentsCollection => 
      _firestore.collection('comments');

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
          _storage.ref().child('posts').child(userId).child('$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Create post document reference
      DocumentReference postRef = _postsCollection.doc();

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
      throw PostException('create-post-error', 'Failed to create post: ${e.toString()}');
    }
  }

  // Get posts for feed (from followed users)
  Future<List<PostModel>> getFeedPosts(UserModel currentUser) async {
    try {
      if (currentUser.following.isEmpty) {
        // If user doesn't follow anyone, just get their own posts and some recent posts
        QuerySnapshot recentPostsSnapshot = await _postsCollection
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
            
        List<PostModel> posts = recentPostsSnapshot.docs
            .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
            
        return posts;
      }
      
      // User follows people, so combine their posts and followed users' posts
      List<String> userIds = [...currentUser.following];
      
      // Add current user's ID for their own posts
      userIds.add(currentUser.id);
      
      // Split into chunks because Firebase has a limit on 'in' queries
      List<List<String>> userIdChunks = [];
      for (var i = 0; i < userIds.length; i += 10) {
        int end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        userIdChunks.add(userIds.sublist(i, end));
      }
      
      List<Future<QuerySnapshot>> queries = [];
      for (var chunk in userIdChunks) {
        queries.add(_postsCollection
            .where('userId', whereIn: chunk)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get());
      }
      
      List<QuerySnapshot> results = await Future.wait(queries);
      
      // Combine results, sort by createdAt, and limit to 50 posts
      List<DocumentSnapshot> allDocs = [];
      for (var result in results) {
        allDocs.addAll(result.docs);
      }
      
      // Sort by createdAt (newest first)
      allDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        Timestamp aTimestamp = aData['createdAt'] as Timestamp;
        Timestamp bTimestamp = bData['createdAt'] as Timestamp;
        
        return bTimestamp.compareTo(aTimestamp);
      });
      
      // Limit to 50 posts
      if (allDocs.length > 50) {
        allDocs = allDocs.sublist(0, 50);
      }
      
      List<PostModel> posts = allDocs
          .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return posts;
    } catch (e) {
      throw PostException('get-feed-posts-error', 'Failed to get feed posts: ${e.toString()}');
    }
  }

  // Get user posts
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      QuerySnapshot postSnapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<PostModel> posts = postSnapshot.docs
          .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return posts;
    } catch (e) {
      throw PostException('get-user-posts-error', 'Failed to get user posts: ${e.toString()}');
    }
  }

  // Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      DocumentSnapshot postSnapshot = await _postsCollection.doc(postId).get();

      if (!postSnapshot.exists) return null;

      return PostModel.fromJson(
          postSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      throw PostException('get-post-error', 'Failed to get post: ${e.toString()}');
    }
  }

  // Stream of posts for real-time updates (feed)
  Stream<List<PostModel>> streamFeedPosts(List<String> followingIds, String userId) {
    try {
      // Combine user's ID with their following list
      List<String> userIds = [...followingIds, userId];
      
      // Handle empty list or Firebase 'in' query limitation
      if (userIds.isEmpty) {
        return Stream.value([]);
      }
      
      // Use a more efficient approach with pagination and limit for better performance
      return _postsCollection
          .where('userId', whereIn: userIds.length > 10 ? userIds.sublist(0, 10) : userIds)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PostModel.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw PostException('stream-feed-error', 'Failed to stream feed posts: ${e.toString()}');
    }
  }

  // Stream of posts for real-time updates (user profile)
  Stream<List<PostModel>> streamUserPosts(String userId) {
    try {
      return _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PostModel.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw PostException('stream-user-posts-error', 'Failed to stream user posts: ${e.toString()}');
    }
  }
  
  // Stream a single post for real-time updates
  Stream<PostModel?> streamPost(String postId) {
    try {
      return _postsCollection
          .doc(postId)
          .snapshots()
          .map((snapshot) => snapshot.exists
              ? PostModel.fromJson(snapshot.data()!)
              : null);
    } catch (e) {
      throw PostException('stream-post-error', 'Failed to stream post: ${e.toString()}');
    }
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw PostException('like-post-error', 'Failed to like post: ${e.toString()}');
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw PostException('unlike-post-error', 'Failed to unlike post: ${e.toString()}');
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
      // Create comment document in separate collection for better scalability
      DocumentReference commentRef = _commentsCollection.doc();
      
      // Create comment object
      CommentModel comment = CommentModel(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        text: text,
        createdAt: DateTime.now(),
      );

      // Save comment to Firestore
      await commentRef.set(comment.toJson());
      
      // Update post with comment count
      await _postsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(1)
      });

      return comment;
    } catch (e) {
      throw PostException('add-comment-error', 'Failed to add comment: ${e.toString()}');
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      QuerySnapshot commentSnapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt')
          .get();

      List<CommentModel> comments = commentSnapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return comments;
    } catch (e) {
      throw PostException('get-comments-error', 'Failed to get comments: ${e.toString()}');
    }
  }
  
  // Stream comments for a post for real-time updates
  Stream<List<CommentModel>> streamPostComments(String postId) {
    try {
      return _commentsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw PostException('stream-comments-error', 'Failed to stream comments: ${e.toString()}');
    }
  }

  // Like a comment
  Future<void> likeComment(String commentId, String userId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw PostException('like-comment-error', 'Failed to like comment: ${e.toString()}');
    }
  }

  // Unlike a comment
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw PostException('unlike-comment-error', 'Failed to unlike comment: ${e.toString()}');
    }
  }
  
  // Delete a comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      // Delete the comment
      await _commentsCollection.doc(commentId).delete();
      
      // Update post with comment count
      await _postsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(-1)
      });
    } catch (e) {
      throw PostException('delete-comment-error', 'Failed to delete comment: ${e.toString()}');
    }
  }

  // Update a post
  Future<void> updatePost(String postId, {String? caption, String? location}) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (caption != null) updateData['caption'] = caption;
      if (location != null) updateData['location'] = location;
      
      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await _postsCollection.doc(postId).update(updateData);
      }
    } catch (e) {
      throw PostException('update-post-error', 'Failed to update post: ${e.toString()}');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Get the post to access the image URL
      DocumentSnapshot postSnapshot = await _postsCollection.doc(postId).get();
      
      if (!postSnapshot.exists) return;

      PostModel post = PostModel.fromJson(
          postSnapshot.data() as Map<String, dynamic>);

      // Delete comments associated with the post
      QuerySnapshot commentsSnapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .get();
          
      WriteBatch batch = _firestore.batch();
      
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete post document
      batch.delete(_postsCollection.doc(postId));
      
      // Execute batch delete
      await batch.commit();

      // Delete post image from Storage if it exists
      if (post.imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(post.imageUrl).delete();
        } catch (e) {
          // Ignore if image doesn't exist
        }
      }
    } catch (e) {
      throw PostException('delete-post-error', 'Failed to delete post: ${e.toString()}');
    }
  }
  
  // Search posts by caption or location
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      // Search for posts with matching caption
      QuerySnapshot captionSnapshot = await _postsCollection
          .where('caption', isGreaterThanOrEqualTo: query)
          .where('caption', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
          
      // Search for posts with matching location
      QuerySnapshot locationSnapshot = await _postsCollection
          .where('location', isGreaterThanOrEqualTo: query)
          .where('location', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
          
      // Combine results, remove duplicates
      Set<String> seenIds = {};
      List<PostModel> results = [];
      
      for (var doc in [...captionSnapshot.docs, ...locationSnapshot.docs]) {
        String id = doc.id;
        if (!seenIds.contains(id)) {
          seenIds.add(id);
          results.add(PostModel.fromJson(doc.data() as Map<String, dynamic>));
        }
      }
      
      return results;
    } catch (e) {
      throw PostException('search-posts-error', 'Failed to search posts: ${e.toString()}');
    }
  }
}