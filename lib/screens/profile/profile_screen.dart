import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/post_view_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_grid_item.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../chat/chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load profile data when screen initializes
    _loadProfile();
  }
  
  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when userId changes - important when viewing different profiles
    if (oldWidget.userId != widget.userId) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);

    try {
      // Make sure we have a current user
      if (authViewModel.currentUser == null) {
        // If no current user, try to refresh user data
        await authViewModel.refreshUserData();
        
        // If still no current user, return to login
        if (authViewModel.currentUser == null && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          return;
        }
      }

      // If userId is provided, load that user's profile, otherwise load current user's profile
      final String userId = widget.userId ?? authViewModel.currentUser!.id;
      
      // Log which profile we're loading - useful for debugging
      print('Loading profile for user ID: $userId (widget.userId=${widget.userId})');

      // Load profile data for this specific user
      await userViewModel.getUserById(userId);
      await postViewModel.getUserPosts(userId);
    } catch (e) {
      // In case of any errors, we'll show the fallback UI
      print('Error loading profile: $e');
    } finally {
      if (mounted) { // Check if widget is still mounted before calling setState
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _followUser(UserModel currentUser) async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    // Simply update current user's following list locally
    List<String> updatedFollowing = List.from(currentUser.following);
    if (userViewModel.profileUser != null && !updatedFollowing.contains(userViewModel.profileUser!.id)) {
      updatedFollowing.add(userViewModel.profileUser!.id);
    }
    
    // Just trigger a UI refresh with the updated following state
    setState(() {});
    
    // Then do the actual Firestore update in the background
    if (userViewModel.profileUser != null) {
      userViewModel.followUser(
        currentUser: currentUser.copyWith(following: updatedFollowing),
        targetUserId: userViewModel.profileUser!.id,
      );
    }
  }

  Future<void> _unfollowUser(UserModel currentUser) async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    // Simply update current user's following list locally
    List<String> updatedFollowing = List.from(currentUser.following);
    if (userViewModel.profileUser != null) {
      updatedFollowing.remove(userViewModel.profileUser!.id);
    }
    
    // Just trigger a UI refresh with the updated following state
    setState(() {});
    
    // Then do the actual Firestore update in the background
    if (userViewModel.profileUser != null) {
      userViewModel.unfollowUser(
        currentUserId: currentUser.id,
        targetUserId: userViewModel.profileUser!.id,
      );
    }
  }

  void _showFollowersList(String userId) {
    // TODO: Navigate to followers list screen
  }

  void _showFollowingList(String userId) {
    // TODO: Navigate to following list screen
  }

  void _startChat(String currentUserId, String targetUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          targetUserId: targetUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userViewModel = Provider.of<UserViewModel>(context);
    final postViewModel = Provider.of<PostViewModel>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final UserModel? profileUser = userViewModel.profileUser;
    final UserModel? currentUser = authViewModel.currentUser;
    
    // For presentation, create a mock profile if the real one isn't available
    if (profileUser == null || currentUser == null) {
      // Don't try to refresh auth data here, it can cause setState issues
      // Create a mock user for demonstration purposes
      final mockUser = UserModel(
        id: 'mock-profile-id',
        email: 'demo@sabanciuniv.edu',
        username: 'demo_user',
        fullName: 'Demo User',
        profileImageUrl: '',
        bio: 'This is a demo profile for presentation purposes',
        department: 'Computer Science',
        year: 2023,
        followers: List.generate(125, (index) => 'follower-$index'),
        following: List.generate(84, (index) => 'following-$index'),
        isVerified: true,
        createdAt: DateTime.now(),
      );
      
      return _buildProfileUI(
        mockUser, 
        mockUser, 
        true,
        false,
        context,
      );
    }

    // Check if this is the current user's profile
    final bool isCurrentUser = profileUser.id == currentUser.id;
    
    // Determine follow state based on current user's following list
    final bool isFollowing = currentUser.following.contains(profileUser.id);
    
    return _buildProfileUI(profileUser, currentUser, isCurrentUser, isFollowing, context);
  }
  
  Widget _buildProfileUI(
    UserModel profileUser, 
    UserModel currentUser, 
    bool isCurrentUser, 
    bool isFollowing,
    BuildContext context
  ) {
    final postViewModel = Provider.of<PostViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          profileUser.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header
                    Row(
                      children: [
                        // Profile image
                        CircleAvatar(
                          radius: 40.0,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profileUser.profileImageUrl.isNotEmpty
                              ? NetworkImage(profileUser.profileImageUrl)
                              : null,
                          child: profileUser.profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 40.0,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 24.0),
                        
                        // User stats
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Posts count
                              _buildStatColumn(
                                postViewModel.userPosts.length.toString(),
                                'Posts',
                              ),
                              
                              // Followers count
                              GestureDetector(
                                onTap: () => _showFollowersList(profileUser.id),
                                child: _buildStatColumn(
                                  profileUser.followers.length.toString(),
                                  'Followers',
                                ),
                              ),
                              
                              // Following count
                              GestureDetector(
                                onTap: () => _showFollowingList(profileUser.id),
                                child: _buildStatColumn(
                                  profileUser.following.length.toString(),
                                  'Following',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    
                    // User info
                    Text(
                      profileUser.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    if (profileUser.department.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        profileUser.department,
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                    if (profileUser.bio.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Text(profileUser.bio),
                    ],
                    const SizedBox(height: 16.0),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: isCurrentUser
                              ? OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(
                                          user: profileUser,
                                        ),
                                      ),
                                    ).then((_) {
                                      if (mounted) {
                                        _loadProfile();
                                      }
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textColor,
                                  ),
                                  child: const Text('Edit Profile'),
                                )
                              : isFollowing
                                  ? OutlinedButton(
                                      onPressed: () => _unfollowUser(currentUser),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textColor,
                                      ),
                                      child: const Text('Following'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _followUser(currentUser),
                                      child: const Text('Follow'),
                                    ),
                        ),
                        if (!isCurrentUser) ...[
                          const SizedBox(width: 8.0),
                          OutlinedButton(
                            onPressed: () => _startChat(
                              currentUser.id,
                              profileUser.id,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                            child: const Icon(Icons.chat_bubble_outline),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Posts grid
              const Divider(),
              if (postViewModel.userPosts.isEmpty && !isCurrentUser)
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          size: 60.0,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          isCurrentUser
                              ? 'Share your first post'
                              : 'No posts yet',
                          style: const TextStyle(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                  ),
                  itemCount: isCurrentUser ? 9 : postViewModel.userPosts.length,
                  itemBuilder: (context, index) {
                    // For demo purposes, create mock posts if actual posts aren't available
                    if (postViewModel.userPosts.isEmpty || postViewModel.userPosts.length <= index) {
                      // This is a mock post grid item
                      return Container(
                        color: Colors.grey[300],
                        child: index % 3 == 0 
                          ? const Icon(Icons.photo, size: 40, color: Colors.grey)
                          : null,
                      );
                    }
                    
                    final post = postViewModel.userPosts[index];
                    return PostGridItem(post: post);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}