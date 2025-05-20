import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String imageUrl;
  final String caption;
  final List<String> likes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String location;
  final int commentCount;
  final Map<String, dynamic>? metadata;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.imageUrl,
    this.caption = '',
    this.likes = const [],
    required this.createdAt,
    this.updatedAt,
    this.location = '',
    this.commentCount = 0,
    this.metadata,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      location: json['location'] ?? '',
      commentCount: json['commentCount'] ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'commentCount': commentCount,
    };
    
    // Add optional fields if they exist
    if (updatedAt != null) {
      data['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    
    if (metadata != null) {
      data['metadata'] = metadata;
    }
    
    return data;
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImageUrl,
    String? imageUrl,
    String? caption,
    List<String>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    int? commentCount,
    Map<String, dynamic>? metadata,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      commentCount: commentCount ?? this.commentCount,
      metadata: metadata ?? this.metadata,
    );
  }
  
  // Helper getters
  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);
  bool get hasComments => commentCount > 0;
  
  // Check if post is owned by user
  bool isOwnedBy(String userId) => this.userId == userId;
  
  // Calculate time ago for display
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String text;
  final List<String> likes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.text,
    this.likes = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'] ?? '',
      text: json['text'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'postId': postId,
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'text': text,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    
    if (updatedAt != null) {
      data['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    
    return data;
  }
  
  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? userProfileImageUrl,
    String? text,
    List<String>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      text: text ?? this.text,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Helper getters
  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);
  
  // Check if comment is owned by user
  bool isOwnedBy(String userId) => this.userId == userId;
  
  // Calculate time ago for display
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}