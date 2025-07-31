import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Debug: Print all available user data
  Future<void> debugUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ [DEBUG] No authenticated user');
        return;
      }

      print('🔍 [DEBUG] Current user UID: ${user.uid}');
      print('🔍 [DEBUG] Firebase Auth displayName: ${user.displayName}');
      print('🔍 [DEBUG] Firebase Auth email: ${user.email}');

      // Check Firestore user document
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('🔍 [DEBUG] Firestore user data: $data');
        
        // Check specific fields
        print('🔍 [DEBUG] name field: ${data['name']}');
        print('🔍 [DEBUG] username field: ${data['username']}');
        print('🔍 [DEBUG] displayName field: ${data['displayName']}');
        print('🔍 [DEBUG] firstName field: ${data['firstName']}');
        print('🔍 [DEBUG] lastName field: ${data['lastName']}');
      } else {
        print('❌ [DEBUG] No Firestore user document found');
      }
    } catch (e) {
      print('❌ [DEBUG] Error debugging user data: $e');
    }
  }

  /// Get the best available display name
  Future<String> getBestDisplayName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Unknown User';

      // First try Firebase Auth displayName
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        print('✅ [DEBUG] Using Firebase Auth displayName: ${user.displayName}');
        return user.displayName!;
      }

      // Then try Firestore user document
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // Try different possible field names - prioritize display name (name field) over username
        final name = data['name'] ?? data['username'] ?? data['displayName'] ?? 
                    data['firstName'] ?? data['fullName'];
        
        if (name != null && name.toString().isNotEmpty) {
          print('✅ [DEBUG] Using Firestore name: $name');
          return name.toString();
        }
      }

      // Fallback to email or UID
      if (user.email != null && user.email!.isNotEmpty) {
        final emailName = user.email!.split('@')[0];
        print('✅ [DEBUG] Using email name: $emailName');
        return emailName;
      }

      // Final fallback
      final shortUid = user.uid.length > 6 ? user.uid.substring(user.uid.length - 6) : user.uid;
      final fallbackName = 'User_$shortUid';
      print('✅ [DEBUG] Using fallback name: $fallbackName');
      return fallbackName;
    } catch (e) {
      print('❌ [DEBUG] Error getting display name: $e');
      return 'Unknown User';
    }
  }
} 