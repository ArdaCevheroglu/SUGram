import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      name: "sugramm",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // For development without Firebase, we'll allow the app to continue
    debugPrint('Firebase initialization failed: $e');
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
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Skip authentication and always show main screen
    return const MainScreen();
    
    /* Original authentication flow - commented out for presentation
    return StreamBuilder(
      stream: Provider.of<AuthViewModel>(context).authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final bool isAuthenticated = snapshot.hasData;
        
        if (isAuthenticated) {
          // Start listening to user notifications
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          if (authViewModel.currentUser != null) {
            Provider.of<NotificationViewModel>(context, listen: false)
                .listenToUserNotifications(authViewModel.currentUser!.id);
          }
          
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
    */
  }
}