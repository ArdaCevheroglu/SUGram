import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/post_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/post_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../profile/profile_screen.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _comments = await postViewModel.getPostComments(widget.post.id);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      final comment = await postViewModel.addComment(
        postId: widget.post.id,
        currentUser: authViewModel.currentUser!,
        text: _commentController.text.trim(),
      );

      if (comment != null) {
        setState(() {
          _comments.add(comment);
        });
      }

      _commentController.clear();
    }
  }

  void _likeComment(String commentId) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      postViewModel.likeComment(
        widget.post.id,
        commentId,
        authViewModel.currentUser!,
      );
      
      // Optimistically update UI
      setState(() {
        final index = _comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          final updatedLikes = List<String>.from(_comments[index].likes);
          if (!updatedLikes.contains(authViewModel.currentUser!.id)) {
            updatedLikes.add(authViewModel.currentUser!.id);
          }
          _comments[index] = _comments[index].copyWith(likes: updatedLikes);
        }
      });
    }
  }

  void _unlikeComment(String commentId) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final postViewModel = Provider.of<PostViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      postViewModel.unlikeComment(
        widget.post.id,
        commentId,
        authViewModel.currentUser!.id,
      );
      
      // Optimistically update UI
      setState(() {
        final index = _comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          final updatedLikes = List<String>.from(_comments[index].likes);
          updatedLikes.remove(authViewModel.currentUser!.id);
          _comments[index] = _comments[index].copyWith(likes: updatedLikes);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final postViewModel = Provider.of<PostViewModel>(context);
    
    // Get the updated post from the view model
    final updatedPost = postViewModel.feedPosts
        .firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          // Post preview
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile image
                GestureDetector(
                  onTap: () => _navigateToUserProfile(updatedPost.userId),
                  child: CircleAvatar(
                    radius: 16.0,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: updatedPost.userProfileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(updatedPost.userProfileImageUrl)
                        : null,
                    child: updatedPost.userProfileImageUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 16.0,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12.0),
                
                // Caption
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToUserProfile(updatedPost.userId),
                            child: Text(
                              updatedPost.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            DateFormatter.formatTimeAgo(updatedPost.createdAt),
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      if (updatedPost.caption.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(updatedPost.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Comments list
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final bool isLiked = authViewModel.currentUser != null &&
                              comment.likes.contains(authViewModel.currentUser!.id);
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User profile image
                                GestureDetector(
                                  onTap: () => _navigateToUserProfile(comment.userId),
                                  child: CircleAvatar(
                                    radius: 16.0,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: comment.userProfileImageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(comment.userProfileImageUrl)
                                        : null,
                                    child: comment.userProfileImageUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 16.0,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                
                                // Comment content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _navigateToUserProfile(comment.userId),
                                            child: Text(
                                              comment.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            DateFormatter.formatTimeAgo(comment.createdAt),
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                              color: AppTheme.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(comment.text),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (isLiked) {
                                                _unlikeComment(comment.id);
                                              } else {
                                                _likeComment(comment.id);
                                              }
                                            },
                                            child: Text(
                                              'Like',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isLiked
                                                    ? AppTheme.primaryColor
                                                    : AppTheme.secondaryTextColor,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16.0),
                                          GestureDetector(
                                            onTap: () {
                                              // Focus on comment input and add @username
                                              _commentController.text = '@${comment.username} ';
                                              _commentController.selection =
                                                  TextSelection.fromPosition(
                                                TextPosition(
                                                  offset: _commentController.text.length,
                                                ),
                                              );
                                              FocusScope.of(context).requestFocus();
                                            },
                                            child: const Text(
                                              'Reply',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.secondaryTextColor,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                          if (comment.likes.isNotEmpty) ...[
                                            const Spacer(),
                                            Text(
                                              '${comment.likes.length} ${comment.likes.length == 1 ? 'like' : 'likes'}',
                                              style: const TextStyle(
                                                color: AppTheme.secondaryTextColor,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Like button
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16.0,
                                    color: isLiked ? AppTheme.secondaryColor : null,
                                  ),
                                  onPressed: () {
                                    if (isLiked) {
                                      _unlikeComment(comment.id);
                                    } else {
                                      _likeComment(comment.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16.0,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: authViewModel.currentUser?.profileImageUrl.isNotEmpty ?? false
                      ? NetworkImage(authViewModel.currentUser!.profileImageUrl)
                      : null,
                  child: authViewModel.currentUser?.profileImageUrl.isEmpty ?? true
                      ? const Icon(
                          Icons.person,
                          size: 16.0,
                          color: Colors.grey,
                        )
                      : null,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _addComment();
                      }
                    },
                  ),
                ),
                TextButton(
                  onPressed: _addComment,
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}