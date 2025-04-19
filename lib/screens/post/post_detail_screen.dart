import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/post_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import 'comments_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoading = true;
  PostModel? _post;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
    });

    final postViewModel = Provider.of<PostViewModel>(context, listen: false);
    final post = await postViewModel.getPostById(widget.postId);

    setState(() {
      _post = post;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Post not found'))
              : Column(
                  children: [
                    // Post card
                    Expanded(
                      child: PostCard(post: _post!),
                    ),
                    
                    // Comment input
                    _buildCommentInput(),
                  ],
                ),
    );
  }

  Widget _buildCommentInput() {
    final TextEditingController commentController = TextEditingController();
    final authViewModel = Provider.of<AuthViewModel>(context);
    final postViewModel = Provider.of<PostViewModel>(context);

    return Container(
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
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.isNotEmpty && _post != null && authViewModel.currentUser != null) {
                  postViewModel.addComment(
                    postId: _post!.id,
                    currentUser: authViewModel.currentUser!,
                    text: value,
                  );
                  commentController.clear();
                }
              },
            ),
          ),
          TextButton(
            onPressed: () {
              if (commentController.text.isNotEmpty && _post != null && authViewModel.currentUser != null) {
                postViewModel.addComment(
                  postId: _post!.id,
                  currentUser: authViewModel.currentUser!,
                  text: commentController.text,
                );
                commentController.clear();
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}