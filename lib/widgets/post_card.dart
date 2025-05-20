import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/post_view_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/post/comments_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  void _navigateToUserProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToPostDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: post.id),
      ),
    );
  }

  void _navigateToComments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(post: post),
      ),
    );
  }

  void _toggleLike(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);
    
    if (authViewModel.currentUser != null) {
      final String userId = authViewModel.currentUser!.id;
      
      if (post.likes.contains(userId)) {
        postViewModel.unlikePost(post.id, userId);
      } else {
        postViewModel.likePost(post.id, authViewModel.currentUser!);
      }
    }
  }

  void _showPostOptions(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);
    final bool isCurrentUserPost = post.userId == authViewModel.currentUser?.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentUserPost) ...[
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete post'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePost(context, postViewModel);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View profile'),
              onTap: () {
                Navigator.pop(context);
                _navigateToUserProfile(context, post.userId);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share post'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement share post
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy link'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement copy link
            },
          ),
          if (!isCurrentUserPost) ...[
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Report post'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report post
              },
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, PostViewModel postViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              postViewModel.deletePost(post.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final bool isLiked = authViewModel.currentUser != null &&
        post.likes.contains(authViewModel.currentUser!.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // User profile image
                GestureDetector(
                  onTap: () => _navigateToUserProfile(context, post.userId),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: post.userProfileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(post.userProfileImageUrl)
                        : null,
                    child: post.userProfileImageUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12.0),
                
                // Username and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(context, post.userId),
                        child: Text(
                          post.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (post.location.isNotEmpty) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          post.location,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Post options
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context),
                ),
              ],
            ),
          ),
          
          // Post image
          GestureDetector(
            onTap: () => _navigateToPostDetail(context),
            onDoubleTap: () => _toggleLike(context),
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              width: double.infinity,
              height: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          
          // Post actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppTheme.secondaryColor : null,
                  ),
                  onPressed: () => _toggleLike(context),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _navigateToComments(context),
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {
                    // TODO: Implement share post
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {
                    // TODO: Implement save post
                  },
                ),
              ],
            ),
          ),
          
          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${post.likes.length} likes',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Caption
          if (post.caption.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppTheme.textColor,
                  ),
                  children: [
                    TextSpan(
                      text: post.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: post.caption,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Comments preview
          if (post.commentCount > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
              child: GestureDetector(
                onTap: () => _navigateToComments(context),
                child: Text(
                  post.commentCount == 1
                      ? 'View 1 comment'
                      : 'View all ${post.commentCount} comments',
                  style: const TextStyle(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ),
            ),
          ],
          
          // Post date
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              DateFormatter.formatTimeAgo(post.createdAt),
              style: const TextStyle(
                fontSize: 12.0,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}