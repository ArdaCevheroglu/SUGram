import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current authenticated user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    String? department,
    int? year,
  }) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String uid = result.user?.uid ?? '';

      // Create a user model
      UserModel user = UserModel(
        id: uid,
        email: email,
        username: username,
        fullName: fullName,
        department: department ?? '',
        year: year ?? 0,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set(user.toJson());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in user with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String uid = result.user?.uid ?? '';

      // Get user data from Firestore
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(uid).get();

      return UserModel.fromJson(
          userSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (!userSnapshot.exists) return null;

      return UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}