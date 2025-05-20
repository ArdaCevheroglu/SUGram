import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/user_view_model.dart';
import 'view_models/post_view_model.dart';
import 'view_models/message_view_model.dart';
import 'view_models/event_view_model.dart';
import 'view_models/notification_view_model.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    // Ensure Firebase is properly initialized
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Enable Firebase Analytics
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    
    // Create demo user for testing
    print('Creating demo user if it doesn\'t exist...');
    await AuthService().createDemoUserIfNotExists();
    print('Demo user check completed');
    
    // Log app open event
    await analytics.logAppOpen();
    print('App open event logged');
    
    // Verify Firebase Auth is working
    print('Current Firebase Auth user: ${FirebaseAuth.instance.currentUser?.uid ?? 'None'}');
  } catch (e) {
    // For development without Firebase, we'll allow the app to continue
    print('Firebase initialization failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => PostViewModel()),
        ChangeNotifierProvider(create: (_) => MessageViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: MaterialApp(
        title: 'SUGram',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/messages': (context) => const ChatListScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initializing = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.initialize();
    } catch (e) {
      print('Auth initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Once initialized, use the stream for auth state changes
    return StreamBuilder(
      stream: Provider.of<AuthViewModel>(context).authStateChanges,
      builder: (context, snapshot) {
        // Handle error state in the stream
        if (snapshot.hasError) {
          print('Auth state stream error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Authentication Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force sign out on error
                      Provider.of<AuthViewModel>(context, listen: false).signOut();
                    },
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Handle waiting state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final bool isAuthenticated = snapshot.hasData;
        
        print('Auth state update - isAuthenticated: $isAuthenticated, currentUser: ${authViewModel.currentUser?.username}');
        
        if (isAuthenticated) {
          if (authViewModel.currentUser != null) {
            // User is authenticated and we have their data
            print('User authenticated with data, proceeding to main screen');
            
            // Start listening to user notifications
            Future.microtask(() {
              try {
                Provider.of<NotificationViewModel>(context, listen: false)
                    .listenToUserNotifications(authViewModel.currentUser!.id);
              } catch (e) {
                print('Error setting up notifications: $e');
              }
            });
            
            return const MainScreen();
          } else {
            // Firebase says we're authenticated but we don't have user data yet
            print('Firebase authenticated but no user data yet, refreshing...');
            
            // Try to refresh user data, but don't get stuck in a loading state
            if (!authViewModel.isLoading) {
              // Use a more direct approach to fetch the user data
              final FirebaseAuth auth = FirebaseAuth.instance;
              if (auth.currentUser != null) {
                print('Trying to load data for Firebase user: ${auth.currentUser!.uid}');
                
                // Force refresh of user data
                Future.microtask(() async {
                  try {
                    await authViewModel.refreshUserData();
                    // If we got the user data but the UI didn't update, force navigation
                    if (authViewModel.currentUser != null) {
                      print('User data loaded successfully through manual refresh');
                      // We need to add a delay to allow the UI to rebuild
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pushReplacementNamed('/main');
                        }
                      });
                    }
                  } catch (e) {
                    print('Error refreshing user data: $e');
                  }
                });
              } else {
                print('No Firebase user exists, forcing sign out');
                Future.microtask(() => authViewModel.signOut());
              }
            }
            
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text('Loading user data...'),
                    const SizedBox(height: 20),
                    // Add a button to allow users to cancel if stuck
                    ElevatedButton(
                      onPressed: () {
                        print('User canceled loading, signing out');
                        authViewModel.signOut();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          // Not authenticated, return to login
          print('Not authenticated, showing login screen');
          return const LoginScreen();
        }
      },
    );
  }
}