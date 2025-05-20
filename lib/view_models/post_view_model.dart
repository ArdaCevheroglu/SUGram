import 'package:flutter/material.dart';
import 'dart:io';
import '../services/post_service.dart';
import '../services/notification_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostViewModel extends ChangeNotifier {
  final PostService _postService = PostService();
  final NotificationService _notificationService = NotificationService();
  
  List<PostModel> _feedPosts = [];
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PostModel> get feedPosts => _feedPosts;
  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new post
  Future<bool> createPost({
    required UserModel currentUser,
    required File imageFile,
    String caption = '',
    String location = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      PostModel post = await _postService.createPost(
        userId: currentUser.id,
        username: currentUser.username,
        userProfileImageUrl: currentUser.profileImageUrl,
        imageFile: imageFile,
        caption: caption,
        location: location,
      );

      // Add to user posts
      _userPosts.insert(0, post);
      
      // Add to feed if showing user's own posts
      if (_feedPosts.isNotEmpty) {
        _feedPosts.insert(0, post);
      }

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

  // Get posts for feed
  Future<void> getFeedPosts(UserModel currentUser) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedPosts = await _postService.getFeedPosts(currentUser);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user posts
  Future<void> getUserPosts(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userPosts = await _postService.getUserPosts(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      return await _postService.getPostById(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      return await _postService.getPostComments(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Like a post
  Future<void> likePost(String postId, UserModel currentUser) async {
    try {
      await _postService.likePost(postId, currentUser.id);

      // Update post in lists
      _updatePostLike(postId, currentUser.id, true);

      // Find the post to get the owner's ID
      PostModel? post = await _postService.getPostById(postId);
      if (post != null) {
        // Create notification for the post owner
        await _notificationService.createLikeNotification(
          userId: post.userId,
          triggerUser: currentUser,
          postId: postId,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _postService.unlikePost(postId, userId);

      // Update post in lists
      _updatePostLike(postId, userId, false);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add a comment to a post
  Future<CommentModel?> addComment({
    required String postId,
    required UserModel currentUser,
    required String text,
  }) async {
    try {
      CommentModel comment = await _postService.addComment(
        postId: postId,
        userId: currentUser.id,
        username: currentUser.username,
        userProfileImageUrl: currentUser.profileImageUrl,
        text: text,
      );

      // Update post in lists with new comment
      _updatePostComment(postId, comment);

      // Find the post to get the owner's ID
      PostModel? post = await _postService.getPostById(postId);
      if (post != null) {
        // Create notification for the post owner
        await _notificationService.createCommentNotification(
          userId: post.userId,
          triggerUser: currentUser,
          postId: postId,
          commentId: comment.id,
          commentText: text,
        );
      }

      notifyListeners();
      return comment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Like a comment
  Future<void> likeComment(
      String postId, String commentId, UserModel currentUser) async {
    try {
      await _postService.likeComment(commentId, currentUser.id);

      // Update comment in posts
      _updateCommentLike(postId, commentId, currentUser.id, true);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Unlike a comment
  Future<void> unlikeComment(
      String postId, String commentId, String userId) async {
    try {
      await _postService.unlikeComment(commentId, userId);

      // Update comment in posts
      _updateCommentLike(postId, commentId, userId, false);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _postService.deletePost(postId);

      // Remove from lists
      _feedPosts.removeWhere((post) => post.id == postId);
      _userPosts.removeWhere((post) => post.id == postId);

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

  // Helper method to update post like in lists
  void _updatePostLike(String postId, String userId, bool isLiked) {
    // Update in feed posts
    for (int i = 0; i < _feedPosts.length; i++) {
      if (_feedPosts[i].id == postId) {
        List<String> updatedLikes = List.from(_feedPosts[i].likes);
        if (isLiked) {
          if (!updatedLikes.contains(userId)) {
            updatedLikes.add(userId);
          }
        } else {
          updatedLikes.remove(userId);
        }
        _feedPosts[i] = _feedPosts[i].copyWith(likes: updatedLikes);
        break;
      }
    }

    // Update in user posts
    for (int i = 0; i < _userPosts.length; i++) {
      if (_userPosts[i].id == postId) {
        List<String> updatedLikes = List.from(_userPosts[i].likes);
        if (isLiked) {
          if (!updatedLikes.contains(userId)) {
            updatedLikes.add(userId);
          }
        } else {
          updatedLikes.remove(userId);
        }
        _userPosts[i] = _userPosts[i].copyWith(likes: updatedLikes);
        break;
      }
    }
  }

  // Helper method to update post with new comment
  void _updatePostComment(String postId, CommentModel comment) {
    // Update in feed posts
    for (int i = 0; i < _feedPosts.length; i++) {
      if (_feedPosts[i].id == postId) {
        // Increment comment count
        _feedPosts[i] = _feedPosts[i].copyWith(
          commentCount: _feedPosts[i].commentCount + 1
        );
        break;
      }
    }

    // Update in user posts
    for (int i = 0; i < _userPosts.length; i++) {
      if (_userPosts[i].id == postId) {
        // Increment comment count
        _userPosts[i] = _userPosts[i].copyWith(
          commentCount: _userPosts[i].commentCount + 1
        );
        break;
      }
    }
  }

  // Helper method to update comment like in posts
  // Note: Since comments are now stored in a separate collection,
  // we don't need to update the post model when a comment's likes change.
  // This method is now a no-op, but we keep it for compatibility.
  void _updateCommentLike(
      String postId, String commentId, String userId, bool isLiked) {
    // No need to update the post model since comments are in a separate collection
    // The comment likes are updated directly in the comments collection by the service
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}