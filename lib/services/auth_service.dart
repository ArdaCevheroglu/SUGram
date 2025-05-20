import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'dart:async';

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current authenticated user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper method for handling Firebase Authentication errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in or use a different email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Contact support.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'The credentials are invalid. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

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
      // Check if username is already taken
      QuerySnapshot usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
          
      if (usernameCheck.docs.isNotEmpty) {
        throw AuthException('username-already-in-use', 'This username is already taken');
      }

      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String uid = result.user?.uid ?? '';
      
      // Send email verification
      await result.user?.sendEmailVerification();

      // Create a user model
      UserModel user = UserModel(
        id: uid,
        email: email,
        username: username,
        fullName: fullName,
        profileImageUrl: '',
        bio: '',
        department: department ?? '',
        year: year ?? 0,
        followers: [],
        following: [],
        isVerified: false,
        createdAt: DateTime.now(),
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set(user.toJson());

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _handleAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('signup-error', e.toString());
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Signing in with email and password');
      
      // Sign in user with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String uid = result.user?.uid ?? '';
      
      if (uid.isEmpty) {
        print('AuthService: Failed to get user ID after sign in');
        throw AuthException('user-id-missing', 'Failed to get user ID after sign in');
      }
      
      print('AuthService: User signed in with Firebase Auth, uid: $uid');

      // Get user data from Firestore
      print('AuthService: Fetching user data from Firestore');
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(uid).get();
          
      if (!userSnapshot.exists) {
        print('AuthService: User document not found in Firestore');
        throw AuthException('user-data-missing', 'User profile data not found');
      }

      // Update last login timestamp
      print('AuthService: Updating last login timestamp');
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Create and return user model
      print('AuthService: Creating user model from Firestore data');
      final userData = userSnapshot.data() as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userData);
      print('AuthService: User signed in successfully: ${userModel.username}');
      
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('AuthService: FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthException(e.code, _handleAuthError(e));
    } catch (e) {
      print('AuthService: Error signing in: ${e.toString()}');
      if (e is AuthException) rethrow;
      throw AuthException('signin-error', e.toString());
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw AuthException('google-signin-canceled', 'Google sign in was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Get the user ID
      String uid = result.user?.uid ?? '';
      
      // Check if this is an existing user
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(uid).get();
      
      // If user doesn't exist in Firestore, create a new profile
      if (!userSnapshot.exists) {
        final User? user = result.user;
        if (user == null) {
          throw AuthException('user-null', 'Failed to get user data after Google sign in');
        }
        
        // Extract username from email (before @)
        String username = user.email?.split('@')[0] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        
        // Check if username exists and make it unique if needed
        QuerySnapshot usernameCheck = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
            
        if (usernameCheck.docs.isNotEmpty) {
          username = '${username}_${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
        
        // Create a new user model
        UserModel newUser = UserModel(
          id: uid,
          email: user.email ?? '',
          username: username,
          fullName: user.displayName ?? '',
          profileImageUrl: user.photoURL ?? '',
          bio: '',
          department: '',
          year: 0,
          followers: [],
          following: [],
          isVerified: user.emailVerified,
          createdAt: DateTime.now(),
        );
        
        // Save user data to Firestore
        await _firestore.collection('users').doc(uid).set(newUser.toJson());
        
        return newUser;
      } else {
        // Update last login timestamp
        await _firestore.collection('users').doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        
        // Return existing user data
        return UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _handleAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('google-signin-error', e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      await _googleSignIn.signOut().catchError((_) {});
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw AuthException('signout-error', 'Failed to sign out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _handleAuthError(e));
    } catch (e) {
      throw AuthException('reset-password-error', e.toString());
    }
  }
  
  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw AuthException('email-verification-error', 'Failed to send verification email: ${e.toString()}');
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('user-not-signed-in', 'No user is signed in');
      }
      
      // Re-authenticate the user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Change the password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _handleAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('change-password-error', e.toString());
    }
  }
  
  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('user-not-signed-in', 'No user is signed in');
      }
      
      // Re-authenticate the user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete the user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _handleAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('delete-account-error', e.toString());
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      throw AuthException('update-profile-error', 'Failed to update profile: ${e.toString()}');
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
      throw AuthException('get-user-data-error', 'Failed to get user data: ${e.toString()}');
    }
  }
  
  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!userSnapshot.exists) return null;

      return UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      throw AuthException('get-user-by-id-error', 'Failed to get user by ID: ${e.toString()}');
    }
  }
  
  // Create demo user if it doesn't exist (for development and demo purposes)
  Future<void> createDemoUserIfNotExists() async {
    try {
      const String demoEmail = 'demo@sabanciuniv.edu';
      const String demoPassword = 'demo123456';
      
      // Check if user exists
      try {
        await _auth.signInWithEmailAndPassword(
          email: demoEmail,
          password: demoPassword,
        );
        // If successful, user exists, so sign out
        await _auth.signOut();
        return;
      } catch (e) {
        // User doesn't exist, continue to create
      }
      
      // Create demo user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
      
      String uid = result.user?.uid ?? '';
      
      UserModel demoUser = UserModel(
        id: uid,
        email: demoEmail,
        username: 'su_demo',
        fullName: 'SUGram Demo',
        profileImageUrl: '',
        bio: 'Demo account for SUGram',
        department: 'Computer Science',
        year: 2023,
        followers: [],
        following: [],
        isVerified: true,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(uid).set(demoUser.toJson());
      
      // Sign out after creating
      await _auth.signOut();
    } catch (e) {
      // Silently fail, don't disrupt app flow
      print('Error creating demo user: $e');
    }
  }
}