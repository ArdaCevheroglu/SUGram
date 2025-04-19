import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../screens/post/post_detail_screen.dart';

class PostGridItem extends StatelessWidget {
  final PostModel post;

  const PostGridItem({super.key, required this.post});

  void _navigateToPostDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: post.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToPostDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Post image
          CachedNetworkImage(
            imageUrl: post.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.error,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          
          // Overlay with likes and comments count
          if (post.likes.isNotEmpty || post.comments.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.likes.isNotEmpty) ...[
                      const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 14.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        post.likes.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                    if (post.likes.isNotEmpty && post.comments.isNotEmpty)
                      const SizedBox(width: 8.0),
                    if (post.comments.isNotEmpty) ...[
                      const Icon(
                        Icons.chat_bubble,
                        color: Colors.white,
                        size: 14.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        post.comments.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}