import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's profile
  Stream<UserProfile?> getCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get user profile by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .update(profile.toFirestore());
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Update specific profile fields
  Future<bool> updateProfileFields(Map<String, dynamic> fields) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      fields['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(fields);
      return true;
    } catch (e) {
      print('Error updating profile fields: $e');
      return false;
    }
  }

  // Update bio
  Future<bool> updateBio(String bio) async {
    return await updateProfileFields({'bio': bio});
  }

  // Update username
  Future<bool> updateUsername(String username) async {
    return await updateProfileFields({'username': username});
  }

  // Update name
  Future<bool> updateName(String name) async {
    return await updateProfileFields({'name': name});
  }

  // Update avatar URL
  Future<bool> updateAvatarUrl(String avatarUrl) async {
    return await updateProfileFields({'avatarUrl': avatarUrl});
  }

  // Update social links
  Future<bool> updateSocialLinks(Map<String, String> socialLinks) async {
    return await updateProfileFields({'socialLinks': socialLinks});
  }

  // Add social link
  Future<bool> addSocialLink(String platform, String url) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'socialLinks.$platform': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding social link: $e');
      return false;
    }
  }

  // Remove social link
  Future<bool> removeSocialLink(String platform) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'socialLinks.$platform': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error removing social link: $e');
      return false;
    }
  }

  // Update media URLs
  Future<bool> updateMediaUrls(List<String> mediaUrls) async {
    return await updateProfileFields({'mediaUrls': mediaUrls});
  }

  // Add media URL
  Future<bool> addMediaUrl(String mediaUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'mediaUrls': FieldValue.arrayUnion([mediaUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding media URL: $e');
      return false;
    }
  }

  // Remove media URL
  Future<bool> removeMediaUrl(String mediaUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'mediaUrls': FieldValue.arrayRemove([mediaUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error removing media URL: $e');
      return false;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      return query.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Get current user UID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
} 