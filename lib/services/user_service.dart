import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!userSnapshot.exists) return null;

      return UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) return null;

      return UserModel.fromJson(
          userSnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // Search users by username or fullName
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Search for username match
      QuerySnapshot usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .get();

      // Search for fullName match
      QuerySnapshot fullNameSnapshot = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThan: query + 'z')
          .get();

      // Combine results without duplicates
      Map<String, UserModel> users = {};

      for (var doc in usernameSnapshot.docs) {
        UserModel user =
            UserModel.fromJson(doc.data() as Map<String, dynamic>);
        users[user.id] = user;
      }

      for (var doc in fullNameSnapshot.docs) {
        UserModel user =
            UserModel.fromJson(doc.data() as Map<String, dynamic>);
        users[user.id] = user;
      }

      return users.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  // Follow user
  Future<void> followUser(
      {required String currentUserId, required String targetUserId}) async {
    try {
      // Add targetUserId to currentUser's following list
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayUnion([targetUserId])
      });

      // Add currentUserId to targetUser's followers list
      await _firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unfollow user
  Future<void> unfollowUser(
      {required String currentUserId, required String targetUserId}) async {
    try {
      // Remove targetUserId from currentUser's following list
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId])
      });

      // Remove currentUserId from targetUser's followers list
      await _firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user followers
  Future<List<UserModel>> getUserFollowers(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!userSnapshot.exists) return [];

      UserModel user =
          UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);

      List<UserModel> followers = [];
      for (String followerId in user.followers) {
        UserModel? follower = await getUserById(followerId);
        if (follower != null) {
          followers.add(follower);
        }
      }

      return followers;
    } catch (e) {
      rethrow;
    }
  }

  // Get user following
  Future<List<UserModel>> getUserFollowing(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!userSnapshot.exists) return [];

      UserModel user =
          UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);

      List<UserModel> following = [];
      for (String followingId in user.following) {
        UserModel? followingUser = await getUserById(followingId);
        if (followingUser != null) {
          following.add(followingUser);
        }
      }

      return following;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }
}