import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String profileImageUrl;
  final String bio;
  final List<String> followers;
  final List<String> following;
  final bool isVerified;
  final String department;
  final int year;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.profileImageUrl = '',
    this.bio = '',
    this.followers = const [],
    this.following = const [],
    this.isVerified = false,
    this.department = '',
    this.year = 0,
    DateTime? createdAt,
    this.lastLoginAt,
    this.settings,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bio: json['bio'] ?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      isVerified: json['isVerified'] ?? false,
      department: json['department'] ?? '',
      year: json['year'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'isVerified': isVerified,
      'department': department,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Add optional fields if they exist
    if (lastLoginAt != null) {
      data['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    }
    
    if (settings != null) {
      data['settings'] = settings;
    }

    return data;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? profileImageUrl,
    String? bio,
    List<String>? followers,
    List<String>? following,
    bool? isVerified,
    String? department,
    int? year,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isVerified: isVerified ?? this.isVerified,
      department: department ?? this.department,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      settings: settings ?? this.settings,
    );
  }

  // Helper method to get follower count
  int get followerCount => followers.length;
  
  // Helper method to get following count
  int get followingCount => following.length;
  
  // Check if this user follows another user
  bool isFollowing(String userId) => following.contains(userId);
  
  // Check if this user is followed by another user
  bool isFollowedBy(String userId) => followers.contains(userId);
}