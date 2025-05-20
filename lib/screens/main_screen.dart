import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/notification_view_model.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'events/events_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // Don't make screens final so they can be recreated when account changes
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }
  
  void _initializeScreens() {
    // Create the screens
    _screens = [
      const HomeScreen(),
      const SearchScreen(),
      const EventsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(), // Profile screen for current user
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final notificationViewModel = Provider.of<NotificationViewModel>(context);
    
    // Important: When user clicks profile tab, ensure it always shows THEIR profile
    if (_currentIndex == 4 && authViewModel.currentUser != null) {
      // Force recreation of profile screen with null userId (which defaults to current user)
      _screens[4] = const ProfileScreen();
    }
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // If selecting the profile tab, ensure it's always the current user's profile
          if (index == 4 && authViewModel.currentUser != null) {
            _screens[4] = const ProfileScreen();
          }
          
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.favorite_border),
                if (notificationViewModel.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        notificationViewModel.unreadCount > 9
                            ? '9+'
                            : notificationViewModel.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.favorite),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _currentIndex == 4
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: authViewModel.currentUser?.profileImageUrl.isNotEmpty ?? false
                    ? Image.network(
                        authViewModel.currentUser!.profileImageUrl,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person_outline),
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}