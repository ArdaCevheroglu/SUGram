import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String imageUrl;
  final String caption;
  final List<String> likes;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final String location;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.imageUrl,
    this.caption = '',
    this.likes = const [],
    this.comments = const [],
    required this.createdAt,
    this.location = '',
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
      comments: (json['comments'] as List<dynamic>?)
              ?.map((comment) => CommentModel.fromJson(comment))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImageUrl,
    String? imageUrl,
    String? caption,
    List<String>? likes,
    List<CommentModel>? comments,
    DateTime? createdAt,
    String? location,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String text;
  final List<String> likes;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.text,
    this.likes = const [],
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'] ?? '',
      text: json['text'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'text': text,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}