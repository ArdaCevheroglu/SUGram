import 'package:flutter/material.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  
  UserModel? _profileUser;
  List<UserModel> _searchResults = [];
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get profileUser => _profileUser;
  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get followers => _followers;
  List<UserModel> get following => _following;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileUser = await _userService.getUserById(userId);
      _isLoading = false;
      notifyListeners();
      return _profileUser;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileUser = await _userService.getUserByUsername(username);
      _isLoading = false;
      notifyListeners();
      return _profileUser;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Search users
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _userService.searchUsers(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Follow user
  Future<bool> followUser({
    required UserModel currentUser,
    required String targetUserId,
  }) async {
    try {
      await _userService.followUser(
        currentUserId: currentUser.id,
        targetUserId: targetUserId,
      );

      // Update profile user if viewing their profile
      if (_profileUser != null && _profileUser!.id == targetUserId) {
        List<String> updatedFollowers = List.from(_profileUser!.followers);
        if (!updatedFollowers.contains(currentUser.id)) {
          updatedFollowers.add(currentUser.id);
        }
        _profileUser = _profileUser!.copyWith(followers: updatedFollowers);
      }

      // Create follow notification
      await _notificationService.createFollowNotification(
        userId: targetUserId,
        triggerUser: currentUser,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Unfollow user
  Future<bool> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _userService.unfollowUser(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      // Update profile user if viewing their profile
      if (_profileUser != null && _profileUser!.id == targetUserId) {
        List<String> updatedFollowers = List.from(_profileUser!.followers);
        updatedFollowers.remove(currentUserId);
        _profileUser = _profileUser!.copyWith(followers: updatedFollowers);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get user followers
  Future<void> getUserFollowers(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _followers = await _userService.getUserFollowers(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user following
  Future<void> getUserFollowing(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _following = await _userService.getUserFollowing(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel user, {File? profileImage}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserModel updatedUser = user;

      // Upload profile image if provided
      if (profileImage != null) {
        String imageUrl = await _storageService.uploadProfileImage(
          user.id,
          profileImage,
        );
        updatedUser = user.copyWith(profileImageUrl: imageUrl);
      }

      await _userService.updateUserProfile(updatedUser);
      _profileUser = updatedUser;

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

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}