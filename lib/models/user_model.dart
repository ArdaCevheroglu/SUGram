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
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
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
    );
  }
}