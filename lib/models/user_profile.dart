import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String phoneNumber;
  final String name;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final Map<String, String> socialLinks;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.username,
    this.bio,
    this.avatarUrl,
    required this.socialLinks,
    required this.mediaUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'],
      avatarUrl: data['avatarUrl'],
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'socialLinks': socialLinks,
      'mediaUrls': mediaUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    Map<String, String>? socialLinks,
    List<String>? mediaUrls,
  }) {
    return UserProfile(
      uid: uid,
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Get display name (name if available, otherwise username)
  String get displayName => name.isNotEmpty ? name : username;

  // Get social link by platform
  String? getSocialLink(String platform) {
    return socialLinks[platform];
  }

  // Check if user has any social links
  bool get hasSocialLinks => socialLinks.isNotEmpty;

  // Check if user has any media
  bool get hasMedia => mediaUrls.isNotEmpty;
} 