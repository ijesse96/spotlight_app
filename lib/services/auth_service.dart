import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes for development testing
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? phoneNumber;
  @override
  final bool isEmailVerified;
  @override
  final bool isAnonymous;
  
  MockUser({
    required this.uid,
    this.phoneNumber,
    this.isEmailVerified = true,
    this.isAnonymous = false,
  });
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  @override
  final User user;
  
  MockUserCredential(this.user);
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _verificationId;
  int? _resendToken;
  Completer<String>? _verificationIdCompleter;

  /// Returns the currently signed-in user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Test Firebase Auth configuration
  Future<void> testFirebaseAuth() async {
    try {
      print('🧪 [TEST] Testing Firebase Auth configuration...');
      print('🧪 [TEST] Firebase app name: ${_auth.app.name}');
      print('🧪 [TEST] Firebase project ID: ${_auth.app.options.projectId}');
      print('🧪 [TEST] Current user: ${_auth.currentUser?.uid ?? 'None'}');
      
      // Test if we can access Firebase Auth
      final authState = _auth.authStateChanges();
      print('🧪 [TEST] Auth state stream created successfully');
      
      // Test if we can access Firestore
      await _firestore.collection('test').limit(1).get();
      print('🧪 [TEST] Firestore access successful');
      
      print('🧪 [TEST] Firebase Auth configuration is working correctly');
    } catch (e) {
      print('🧪 [TEST] Firebase Auth test failed: $e');
      rethrow;
    }
  }

  /// Signs in the user anonymously using FirebaseAuth
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  /// Sends SMS verification code to the provided phone number
  Future<void> sendPhoneVerification(String phoneNumber) async {
    try {
      print('🔥 [AUTH] Starting phone verification for: $phoneNumber');
      print('🔥 [AUTH] Firebase Auth instance: ${_auth.app.name}');
      print('🔥 [AUTH] Current user: ${_auth.currentUser?.uid ?? 'None'}');
      print('🔥 [AUTH] Is test number: ${isTestNumber(phoneNumber)}');
      
      // Clear any existing verification ID and create a new completer
      _verificationId = null;
      _resendToken = null;
      _verificationIdCompleter = Completer<String>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🔥 [AUTH] Auto-verification completed for: $phoneNumber');
          print('🔥 [AUTH] This is likely a test number with auto-verification');
          try {
            await _auth.signInWithCredential(credential);
            print('🔥 [AUTH] Auto-sign in successful');
            // For test numbers, we don't need to navigate manually as the auth state will change
          } catch (e) {
            print('🔥 [AUTH] Auto-sign in failed: $e');
            rethrow;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔥 [AUTH] Verification failed:');
          print('🔥 [AUTH] Error code: ${e.code}');
          print('🔥 [AUTH] Error message: ${e.message}');
          print('🔥 [AUTH] Error details: ${e.toString()}');
          // Clear verification data on failure
          _verificationId = null;
          _resendToken = null;
          if (!_verificationIdCompleter!.isCompleted) {
            _verificationIdCompleter!.completeError(e);
          }
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🔥 [AUTH] Code sent successfully!');
          print('🔥 [AUTH] Verification ID: ${verificationId.substring(0, 10)}...');
          print('🔥 [AUTH] Resend token: $resendToken');
          // Store verificationId and resendToken for later use
          _verificationId = verificationId;
          _resendToken = resendToken;
          print('🔥 [AUTH] Verification ID stored: ${_verificationId?.substring(0, 10)}...');
          
          // Complete the completer with the verification ID (if it exists)
          if (_verificationIdCompleter != null && !_verificationIdCompleter!.isCompleted) {
            _verificationIdCompleter!.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🔥 [AUTH] Code auto-retrieval timeout');
          print('🔥 [AUTH] Verification ID: ${verificationId.substring(0, 10)}...');
          _verificationId = verificationId;
          print('🔥 [AUTH] Verification ID set in timeout callback');
          
          // Complete the completer with the verification ID (if it exists)
          if (_verificationIdCompleter != null && !_verificationIdCompleter!.isCompleted) {
            _verificationIdCompleter!.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 120), // Increased timeout
      );
      
      print('🔥 [AUTH] verifyPhoneNumber call completed');
      
      // For test numbers, we don't wait here anymore - we'll wait in verifyTestPhoneCode
      if (isTestNumber(phoneNumber)) {
        print('🔥 [AUTH] Test number detected, verification ID will be available in timeout callback');
      }
    } catch (e) {
      print('🔥 [AUTH] Exception in sendPhoneVerification:');
      print('🔥 [AUTH] Error type: ${e.runtimeType}');
      print('🔥 [AUTH] Error message: $e');
      rethrow;
    }
  }

  /// Check if the phone number is a test number
  bool isTestNumber(String phoneNumber) {
    // Common test number patterns
    final testPatterns = [
      '+15555550000', // Firebase test number
      '+15555550001',
      '+15555550002',
      '+15555550003',
      '+15555550004',
      '+15555550005',
      '+15555550006',
      '+15555550007',
      '+15555550008',
      '+15555550009',
    ];
    return testPatterns.contains(phoneNumber);
  }

  /// Verifies the SMS code and signs in the user
  Future<UserCredential> verifyPhoneCode(String smsCode) async {
    try {
      print('🔥 [AUTH] Verifying SMS code: $smsCode');
      print('🔥 [AUTH] Verification ID exists: ${_verificationId != null}');
      print('🔥 [AUTH] Verification ID: ${_verificationId?.substring(0, 10) ?? 'null'}...');
      
      if (_verificationId == null) {
        throw FirebaseAuthException(
          code: 'invalid-verification-id',
          message: 'Verification ID is null. Please request a new code.',
        );
      }
      
      print('🔥 [AUTH] Creating credential with verification ID: ${_verificationId!.substring(0, 10)}...');
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      print('🔥 [AUTH] Signing in with credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('🔥 [AUTH] Sign in successful: ${userCredential.user?.uid}');
      
      // Clear verification data after successful sign in
      _verificationId = null;
      _resendToken = null;
      
      return userCredential;
    } catch (e) {
      print('🔥 [AUTH] Error in verifyPhoneCode:');
      print('🔥 [AUTH] Error type: ${e.runtimeType}');
      print('🔥 [AUTH] Error message: $e');
      
      // If it's an invalid verification ID error, clear the data
      if (e.toString().contains('invalid-verification-id') || 
          e.toString().contains('session-expired')) {
        _verificationId = null;
        _resendToken = null;
      }
      
      rethrow;
    }
  }

  /// Verifies test phone numbers with manual credential creation
  Future<UserCredential?> verifyTestPhoneCode(String phoneNumber, String smsCode) async {
    try {
      print(' [AUTH] Verifying test phone code for: $phoneNumber');
      print(' [AUTH] Test SMS code: $smsCode');
      
      // Check if we have a verification ID
      String? verificationId = _verificationId;
      print(' [AUTH] Current verification ID: $verificationId');
      print(' [AUTH] Has verification ID: $hasVerificationId');
      
      if (verificationId == null) {
        print(' [AUTH] No verification ID available for test number');
        print(' [AUTH] This means the verification ID was not set during sendPhoneVerification');
        throw FirebaseAuthException(
          code: 'invalid-verification-id',
          message: 'No verification ID available. Please request a new code first.',
        );
      }
      
      print(' [AUTH] Using verification ID: ${verificationId.substring(0, 10)}...');
      
      // Create phone auth credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Sign in with credential
      print(' [AUTH] Signing in with credential...');
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      print(' [AUTH] Sign in successful: ${userCredential.user?.uid}');
      
      // Clear verification data after successful sign in
      _verificationId = null;
      _resendToken = null;
      _verificationIdCompleter = null;
      
      return userCredential;
      
    } catch (e) {
      print(' [AUTH] Error in verifyTestPhoneCode:');
      print(' [AUTH] Error type: ${e.runtimeType}');
      print(' [AUTH] Error message: $e');
      rethrow;
    }
  }

  /// Resends the SMS verification code
  Future<void> resendPhoneVerification(String phoneNumber) async {
    try {
      print('🔥 [AUTH] Resending phone verification for: $phoneNumber');
      print('🔥 [AUTH] Resend token exists: ${_resendToken != null}');
      
      if (_resendToken == null) {
        // If no resend token, start a new verification
        await sendPhoneVerification(phoneNumber);
        return;
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🔥 [AUTH] Auto-verification completed for: $phoneNumber');
          try {
            await _auth.signInWithCredential(credential);
            print('🔥 [AUTH] Auto-sign in successful');
          } catch (e) {
            print('🔥 [AUTH] Auto-sign in failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔥 [AUTH] Resend verification failed:');
          print('🔥 [AUTH] Error code: ${e.code}');
          print('🔥 [AUTH] Error message: ${e.message}');
          // Clear verification data on failure
          _verificationId = null;
          _resendToken = null;
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🔥 [AUTH] Resend code sent successfully!');
          print('🔥 [AUTH] New verification ID: ${verificationId.substring(0, 10)}...');
          print('🔥 [AUTH] New resend token: $resendToken');
          // Update verification data
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🔥 [AUTH] Resend code auto-retrieval timeout');
          print('🔥 [AUTH] Verification ID: ${verificationId.substring(0, 10)}...');
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 120),
      );
      
      print('🔥 [AUTH] Resend verifyPhoneNumber call completed');
    } catch (e) {
      print('🔥 [AUTH] Exception in resendPhoneVerification:');
      print('🔥 [AUTH] Error type: ${e.runtimeType}');
      print('🔥 [AUTH] Error message: $e');
      rethrow;
    }
  }

  /// Checks if user exists in Firestore
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  /// Creates a new user document in Firestore
  Future<void> createUserDocument({
    required String uid,
    required String phoneNumber,
    required String name,
    required String username,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'phoneNumber': phoneNumber,
        'name': name,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Getter to check if verification ID exists
  bool get hasVerificationId => _verificationId != null;
  
  /// Getter to get the current verification ID (for debugging)
  String? get verificationId => _verificationId;

  /// Debug method to print current state
  void debugVerificationState() {
    print('🔥 [DEBUG] Verification ID: ${_verificationId?.substring(0, 10) ?? 'null'}...');
    print('🔥 [DEBUG] Resend token: $_resendToken');
    print('🔥 [DEBUG] Has verification ID: $hasVerificationId');
  }

  /// Test method to check if Firebase is working
  Future<void> testFirebaseConnection() async {
    try {
      print('🔥 [TEST] Testing Firebase connection...');
      print('🔥 [TEST] Firebase Auth instance: ${_auth.app.name}');
      print('🔥 [TEST] Current user: ${_auth.currentUser?.uid ?? 'None'}');
      print('🔥 [TEST] Firebase Auth state: ${_auth.authStateChanges()}');
      
      // Try to get the current auth state
      final authState = await _auth.authStateChanges().first;
      print('🔥 [TEST] Auth state: $authState');
      
    } catch (e) {
      print('🔥 [TEST] Firebase connection test failed: $e');
    }
  }

  /// Alternative method for test numbers that doesn't rely on verification ID
  Future<UserCredential> verifyTestPhoneCodeAlternative(String phoneNumber, String smsCode) async {
    try {
      print('🔥 [AUTH] Alternative test verification for: $phoneNumber');
      print('🔥 [AUTH] Test SMS code: $smsCode');
      
      // For development purposes, create a mock user credential for test numbers
      // This bypasses Firebase authentication for test numbers
      print('🔥 [AUTH] Creating mock user credential for development...');
      
      // Create a mock user credential that simulates successful authentication
      // This is only for development/testing purposes
      final mockUser = MockUser(
        uid: 'test_user_${phoneNumber.replaceAll('+', '')}',
        phoneNumber: phoneNumber,
        isEmailVerified: true,
        isAnonymous: false,
      );
      
      final mockCredential = MockUserCredential(mockUser);
      
      print('🔥 [AUTH] Mock user created: ${mockUser.uid}');
      print('🔥 [AUTH] Mock authentication successful');
      
      return mockCredential;
      
    } catch (e) {
      print('🔥 [AUTH] Error in alternative test verification:');
      print('🔥 [AUTH] Error type: ${e.runtimeType}');
      print('🔥 [AUTH] Error message: $e');
      rethrow;
    }
  }

  /// Clear the verification ID (useful for retry scenarios)
  void clearVerificationId() {
    _verificationId = null;
    _resendToken = null;
    print('🔥 [AUTH] Verification ID and resend token cleared');
  }
} 