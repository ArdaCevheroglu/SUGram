import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/post_view_model.dart';
import '../../widgets/post_card.dart';
import '../../theme/app_theme.dart';
import '../post/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadFeedPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedPosts() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null) {
      await postViewModel.getFeedPosts(authViewModel.currentUser!);
    }
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await _loadFeedPosts();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final postViewModel = Provider.of<PostViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SUGram',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // Navigate to messages screen
              Navigator.pushNamed(context, '/messages');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: postViewModel.isLoading && !_isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : postViewModel.feedPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 80.0,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Follow users or create your first post',
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostScreen(),
                              ),
                            );
                          },
                          child: const Text('Create a Post'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: postViewModel.feedPosts.length,
                    itemBuilder: (context, index) {
                      final post = postViewModel.feedPosts[index];
                      return PostCard(post: post);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}