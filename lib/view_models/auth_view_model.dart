import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Initialize the view model
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if there's a current Firebase user and get their data
      if (_authService.currentUser != null) {
        _currentUser = await _authService.getCurrentUserData();
        print('User initialized: ${_currentUser?.username}');
      } else {
        print('No current Firebase user');
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Auth initialization error: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    String? department,
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        department: department,
        year: year,
      );

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

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting to sign in user: $email');
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      
      if (_currentUser == null) {
        _error = 'Authentication succeeded but user data could not be loaded';
        print('Sign-in error: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      print('User signed in successfully: ${_currentUser?.username}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Sign-in error: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithGoogle();

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

  // Sign out
  Future<bool> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthViewModel: Signing out user');
      
      // Clear all user-related data from memory first
      String? prevUserId = _currentUser?.id;
      print('Signing out user: ${_currentUser?.username} ($prevUserId)');
      _currentUser = null;
      
      // Then sign out from Firebase
      await _authService.signOut();
      
      // Force navigation to login screen by calling signOut on FirebaseAuth directly
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print('Additional sign out error: $e');
      }
      
      // Also clear user data in other view models if needed
      // This can be done through a shared event bus or by directly accessing
      // the view models if they're accessible
      
      print('AuthViewModel: User signed out successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('AuthViewModel: Error signing out: $_error');
      
      // Still set current user to null to force UI to login screen
      _currentUser = null;
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);

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
  
  // Send email verification
  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();

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
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(currentPassword, newPassword);

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
  
  // Delete account
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(password);
      _currentUser = null;

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

  // Update user profile
  Future<bool> updateUserProfile(UserModel user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(user);
      _currentUser = user;

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

  // Refresh current user data
  Future<void> refreshUserData() async {
    try {
      // Set loading state
      _isLoading = true;
      notifyListeners();
      
      // Check if Firebase has a current user
      if (_authService.currentUser == null) {
        print('Cannot refresh user data: No Firebase user');
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get updated user data
      _currentUser = await _authService.getCurrentUserData();
      print('User data refreshed: ${_currentUser?.username}');
      
      // Clear loading and notify
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error refreshing user data: $_error');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}