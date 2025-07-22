
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';

class QueueService {
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileService _profileService = ProfileService();

  // Persistent timers that run independently of UI
  static Timer? _spotlightTimer;
  static Timer? _cityTimer;
  static Timer? _nearbyTimer;
  static Timer? _vlrTimer;
  static bool _isDisposed = false;

  // Collection references
  CollectionReference get _queueCollection => _firestore.collection('spotlight_queue');
  CollectionReference get _liveUserCollection => _firestore.collection('live_users');
  
  // Local queue collections (location-based)
  CollectionReference _getLocalQueueCollection(String locationId) => 
      _firestore.collection('local_queue_$locationId');
  CollectionReference _getLocalLiveUserCollection(String locationId) => 
      _firestore.collection('local_live_users_$locationId');
  CollectionReference _getLocalTimerCollection(String locationId) => 
      _firestore.collection('local_timer_$locationId');

  /// Get the correct user display name from Firestore profile or fallback to Firebase Auth
  Future<String> _getUserDisplayName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Unknown User';

      // Try to get the user profile from Firestore first
      final profile = await _profileService.getUserProfile(user.uid);
      if (profile != null) {
        // Use the custom display name from profile (username if available, otherwise name)
        final displayName = profile.displayName;
        if (displayName.isNotEmpty) {
          return displayName;
        }
      }

      // Fallback to Firebase Auth displayName
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      }

      // Final fallback: generate a unique name using last 6 characters of UID
      final shortUid = user.uid.length > 6 ? user.uid.substring(user.uid.length - 6) : user.uid;
      return 'User_$shortUid';
    } catch (e) {
      print('Error getting user display name: $e');
      // Fallback to Firebase Auth displayName or generated name
      final user = _auth.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        return user.displayName!;
      }
      final shortUid = (user?.uid.length ?? 0) > 6 ? user!.uid.substring(user.uid.length - 6) : user?.uid ?? 'Unknown';
      return 'User_$shortUid';
    }
  }

  /// Get current live user
  Stream<Map<String, dynamic>?> getCurrentLiveUser() {
    return _liveUserCollection
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get queue users
  Stream<List<Map<String, dynamic>>> getQueueUsers() {
    return _queueCollection
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Join the queue
  Future<void> joinQueue() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return;
      }

      final uid = user.uid;
      print('Joining main spotlight queue with UID: $uid');

      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Using display name: $userName');

      // Stop any other active timers to prevent conflicts
      _stopPersistentVLRTimer();
      _stopPersistentCityTimer();
      _stopPersistentNearbyTimer();

      // Check if there's already a live user
      final liveUsers = await _liveUserCollection
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();

      if (liveUsers.docs.isEmpty) {
        // No live user, start the timer and make this user live
        await _queueCollection.doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Initialize timer if it doesn't exist
        await initializeSpotlightTimer();
        
        // Set this user as live immediately (this will start the persistent timer)
        await setUserAsLive(uid, userName);
        
        print('Started main spotlight queue with user: $userName as live');
      } else {
        // There's already a live user, just add to queue
        await _queueCollection.doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        print('Added user to main spotlight queue: $userName');
      }

      print('Successfully joined queue for user: $uid with name: $userName');
    } catch (e) {
      print('Error joining queue: $e');
    }
  }

  /// Update ready status
  Future<void> updateReadyStatus(bool isReady) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Use document ID directly since we store documents with UID as document ID
    await _queueCollection.doc(user.uid).update({
      'ready': isReady,
    });
  }

  /// Leave the queue
  Future<void> leaveQueue() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Use document ID directly since we store documents with UID as document ID
    await _queueCollection.doc(user.uid).delete();
  }

  /// Set user as live
  Future<void> setUserAsLive(String userId, String userName) async {
    // Remove user from queue
    final queueDoc = await _queueCollection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueDoc.docs.isNotEmpty) {
      await queueDoc.docs.first.reference.delete();
    }

    // Clear any existing live users
    final liveUsers = await _liveUserCollection
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }

    // Set new live user
    await _liveUserCollection.add({
      'userId': userId,
      'name': userName,
      'isLive': true,
      'startTime': FieldValue.serverTimestamp(),
    });
    
    // Activate the timer when a user becomes live
    await updateSpotlightTimer(20, true);
    
    // Start the persistent timer
    _startPersistentSpotlightTimer();
  }

  /// End current live session
  Future<void> endLiveSession() async {
    final liveUsers = await _liveUserCollection
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }
    
    // Deactivate the timer when live session ends
    await updateSpotlightTimer(20, false);
  }

  /// Get next ready user from queue
  Future<Map<String, dynamic>?> getNextReadyUser() async {
    final readyUsers = await _queueCollection
        .where('ready', isEqualTo: true)
        .orderBy('timestamp', descending: false)
        .limit(1)
        .get();

    if (readyUsers.docs.isNotEmpty) {
      final doc = readyUsers.docs.first;
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }
    return null;
  }

  /// Check if current user is in queue
  Stream<bool> isUserInQueue() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _queueCollection
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Get current user's queue status
  Stream<Map<String, dynamic>?> getCurrentUserQueueStatus() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    // Use document ID directly since we store documents with UID as document ID
    return _queueCollection.doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get spotlight timer state
  Stream<Map<String, dynamic>?> getSpotlightTimer() {
    return _firestore.collection('spotlight_timer').doc('current').snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Initialize spotlight timer
  Future<void> initializeSpotlightTimer() async {
    await _firestore.collection('spotlight_timer').doc('current').set({
      'countdown': 20,
      'isActive': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Update spotlight timer
  Future<void> updateSpotlightTimer(int countdown, bool isActive) async {
    await _firestore.collection('spotlight_timer').doc('current').update({
      'countdown': countdown,
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Reset spotlight timer
  Future<void> resetSpotlightTimer() async {
    await _firestore.collection('spotlight_timer').doc('current').update({
      'countdown': 20,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    
    // Start the persistent timer
    _startPersistentSpotlightTimer();
  }

  /// Start persistent spotlight timer
  void _startPersistentSpotlightTimer() {
    _spotlightTimer?.cancel();
    print('Starting persistent spotlight timer');
    
    _spotlightTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (_isDisposed) {
          timer.cancel();
          _spotlightTimer = null;
          return;
        }
        
        // Get current timer data
        final timerData = await getSpotlightTimer().first;
        if (timerData != null) {
          final countdown = timerData['countdown'] ?? 20;
          final isActive = timerData['isActive'] ?? false;
          
          if (isActive) {
            final newCountdown = countdown - 1;
            print('Persistent spotlight timer - Decrementing to: $newCountdown');
            
            if (newCountdown <= 0) {
              // Timer finished, move to next user
              print('Persistent spotlight timer finished, moving to next streamer');
              timer.cancel();
              _spotlightTimer = null;
              await _moveToNextSpotlightStreamer();
            } else {
              // Update the timer in Firestore
              await updateSpotlightTimer(newCountdown, true);
            }
          } else {
            print('Persistent spotlight timer is not active, stopping');
            timer.cancel();
            _spotlightTimer = null;
          }
        }
      } catch (e) {
        print('Error in persistent spotlight timer: $e');
        timer.cancel();
        _spotlightTimer = null;
      }
    });
  }

  /// Stop persistent spotlight timer
  void _stopPersistentSpotlightTimer() {
    _spotlightTimer?.cancel();
    _spotlightTimer = null;
    print('Stopped persistent spotlight timer');
  }

  /// Ensure persistent spotlight timer is running
  Future<void> ensurePersistentSpotlightTimerRunning() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final liveUser = await getCurrentLiveUser().first;
      final hasLiveUser = liveUser != null;
      final isCurrentUserLive = hasLiveUser && liveUser['userId'] == user.uid;

      if (hasLiveUser && isCurrentUserLive) {
        // Only the live user's device should run the timer
        final timerData = await getSpotlightTimer().first;
        if (timerData != null) {
          final isActive = timerData['isActive'] ?? false;
          if (!isActive) {
            print('Spotlight Timer exists but not active, activating it for live user');
            await updateSpotlightTimer(timerData['countdown'] ?? 20, true);
            _startPersistentSpotlightTimer();
          } else if (_spotlightTimer == null) {
            print('Spotlight Timer is active but persistent timer not running, starting it');
            _startPersistentSpotlightTimer();
          }
        } else {
          print('No spotlight timer found, creating new timer for live user');
          await resetSpotlightTimer();
        }
      } else {
        print('Not the live user, will not start timer.');
      }
    } catch (e) {
      print('Error ensuring persistent spotlight timer: $e');
    }
  }

  /// Move to next spotlight streamer
  Future<void> _moveToNextSpotlightStreamer() async {
    // Stop the current timer before moving to next user
    _spotlightTimer?.cancel();
    _spotlightTimer = null;
    
    final queueUsers = await getQueueUsers().first;
    
    if (queueUsers.isNotEmpty) {
      final nextUser = queueUsers.first;
      final userName = nextUser['name'] as String?;
      final displayName = (userName != null && userName.isNotEmpty) ? userName : "Unknown User";
      
      await setUserAsLive(nextUser['userId'], displayName);
      print('Moved to next spotlight streamer: $displayName');
      // setUserAsLive already starts the persistent timer
    } else {
      await endLiveSession();
      print('No users in spotlight queue, ended live session');
    }
  }

  // ===== SPOTLIGHT CHAT & GIFTS METHODS =====
  
  /// Get spotlight chat messages
  Stream<List<Map<String, dynamic>>> getSpotlightChatMessages() {
    return _firestore.collection('spotlight_chat')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Send spotlight chat message
  Future<void> sendSpotlightChatMessage(String username, String message, {bool isGift = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('spotlight_chat').add({
      'username': username,
      'message': message,
      'isGift': isGift,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get spotlight gift total
  Stream<int> getSpotlightGiftTotal() {
    return _firestore.collection('spotlight_gifts')
        .doc('total')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data()?['total'] ?? 0;
      }
      return 0;
    });
  }

  /// Add spotlight gift
  Future<void> addSpotlightGift(String giftName, int coinAmount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Don't send individual gift message to chat - only combo messages will be sent
    // await sendSpotlightChatMessage("GiftSender", giftName, isGift: true);

    // Update gift total
    await _firestore.collection('spotlight_gifts').doc('total').set({
      'total': FieldValue.increment(coinAmount),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Reset spotlight gift total
  Future<void> resetSpotlightGiftTotal() async {
    await _firestore.collection('spotlight_gifts').doc('total').set({
      'total': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }





  // ===== LOCAL QUEUE METHODS =====
  
  /// Get current local live user
  Stream<Map<String, dynamic>?> getCurrentLocalLiveUser(String locationId) {
    return _getLocalLiveUserCollection(locationId)
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get local queue users
  Stream<List<Map<String, dynamic>>> getLocalQueueUsers(String locationId) {
    return _getLocalQueueCollection(locationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Join local queue
  Future<void> joinLocalQueue(String locationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return;
      }

      final uid = user.uid;
      print('Joining local queue for location $locationId with UID: $uid');

      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Using display name for local queue: $userName');

      // Use UID as document ID and call .set() instead of .add()
      await _getLocalQueueCollection(locationId).doc(uid).set({
        'userId': uid,
        'name': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Successfully joined local queue for location $locationId, user: $uid with name: $userName');
    } catch (e) {
      print('Error joining local queue: $e');
    }
  }

  /// Leave local queue
  Future<void> leaveLocalQueue(String locationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Use document ID directly since we store documents with UID as document ID
    await _getLocalQueueCollection(locationId).doc(user.uid).delete();
  }

  /// Set user as local live
  Future<void> setUserAsLocalLive(String locationId, String userId, String userName) async {
    // Remove user from local queue
    final queueDoc = await _getLocalQueueCollection(locationId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueDoc.docs.isNotEmpty) {
      await queueDoc.docs.first.reference.delete();
    }

    // Clear any existing local live users
    final liveUsers = await _getLocalLiveUserCollection(locationId)
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }

    // Set new local live user
    await _getLocalLiveUserCollection(locationId).add({
      'userId': userId,
      'name': userName,
      'isLive': true,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  /// End current local live session
  Future<void> endLocalLiveSession(String locationId) async {
    final liveUsers = await _getLocalLiveUserCollection(locationId)
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }
  }

  /// Get current user's local queue status
  Stream<Map<String, dynamic>?> getCurrentUserLocalQueueStatus(String locationId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    // Use document ID directly since we store documents with UID as document ID
    return _getLocalQueueCollection(locationId).doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get local timer state
  Stream<Map<String, dynamic>?> getLocalTimer(String locationId) {
    return _getLocalTimerCollection(locationId).doc('current').snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Initialize local timer
  Future<void> initializeLocalTimer(String locationId) async {
    await _getLocalTimerCollection(locationId).doc('current').set({
      'countdown': 15,
      'isActive': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Update local timer
  Future<void> updateLocalTimer(String locationId, int countdown, bool isActive) async {
    await _getLocalTimerCollection(locationId).doc('current').update({
      'countdown': countdown,
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Reset local timer
  Future<void> resetLocalTimer(String locationId) async {
    await _getLocalTimerCollection(locationId).doc('current').update({
      'countdown': 15,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ===== CITY QUEUE METHODS =====
  
  /// Get city queue users
  Stream<List<Map<String, dynamic>>> getCityQueueUsers(String cityId) {
    return _firestore.collection('city_queue_$cityId')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Set city user as live
  Future<void> setCityUserAsLive(String cityId, String userId, String userName) async {
    // Remove user from city queue
    final queueDoc = await _firestore.collection('city_queue_$cityId')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueDoc.docs.isNotEmpty) {
      await queueDoc.docs.first.reference.delete();
    }

    // Clear any existing city live users
    final liveUsers = await _firestore.collection('city_live_users_$cityId')
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }

    // Set new city live user
    await _firestore.collection('city_live_users_$cityId').add({
      'userId': userId,
      'name': userName,
      'isLive': true,
      'startTime': FieldValue.serverTimestamp(),
    });
    
    // Activate the timer when a user becomes live
    await updateCityTimer(cityId, 20, true);
    
    // Start the persistent timer
    _startPersistentCityTimer(cityId);
  }

  /// End city live session
  Future<void> endCityLiveSession(String cityId) async {
    final liveUsers = await _firestore.collection('city_live_users_$cityId')
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }
    
    // Deactivate the timer when live session ends
    await updateCityTimer(cityId, 20, false);
  }

  /// Get city timer
  Stream<Map<String, dynamic>?> getCityTimer(String cityId) {
    return _firestore.collection('city_timer_$cityId').doc('current').snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Initialize city timer
  Future<void> initializeCityTimer(String cityId) async {
    print('Initializing city timer for city: $cityId');
    await _firestore.collection('city_timer_$cityId').doc('current').set({
      'countdown': 20,
      'isActive': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    print('City timer initialized successfully');
  }

  /// Update city timer
  Future<void> updateCityTimer(String cityId, int countdown, bool isActive) async {
    print('Updating city timer - City: $cityId, Countdown: $countdown, IsActive: $isActive');
    await _firestore.collection('city_timer_$cityId').doc('current').update({
      'countdown': countdown,
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    print('City timer updated successfully');
  }

  /// Reset city timer
  Future<void> resetCityTimer(String cityId) async {
    await _firestore.collection('city_timer_$cityId').doc('current').update({
      'countdown': 20,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    
    // Start the persistent timer
    _startPersistentCityTimer(cityId);
  }

  /// Start persistent city timer
  void _startPersistentCityTimer(String cityId) {
    _cityTimer?.cancel();
    print('Starting persistent city timer for city: $cityId');
    
    _cityTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (_isDisposed) {
          timer.cancel();
          _cityTimer = null;
          return;
        }
        
        // Get current timer data
        final timerData = await getCityTimer(cityId).first;
        if (timerData != null) {
          final countdown = timerData['countdown'] ?? 20;
          final isActive = timerData['isActive'] ?? false;
          
          if (isActive) {
            final newCountdown = countdown - 1;
            print('Persistent city timer - Decrementing to: $newCountdown');
            
            if (newCountdown <= 0) {
              // Timer finished, move to next user
              print('Persistent city timer finished, moving to next streamer');
              timer.cancel();
              _cityTimer = null;
              await _moveToNextCityStreamer(cityId);
            } else {
              // Update the timer in Firestore
              await updateCityTimer(cityId, newCountdown, true);
            }
          } else {
            print('Persistent city timer is not active, stopping');
            timer.cancel();
            _cityTimer = null;
          }
        }
      } catch (e) {
        print('Error in persistent city timer: $e');
        timer.cancel();
        _cityTimer = null;
      }
    });
  }

  /// Stop persistent city timer
  void _stopPersistentCityTimer() {
    _cityTimer?.cancel();
    _cityTimer = null;
    print('Stopped persistent city timer');
  }

  /// Stop persistent VLR timer
  void _stopPersistentVLRTimer() {
    _vlrTimer?.cancel();
    _vlrTimer = null;
    print('Stopped persistent VLR timer');
  }

  /// Stop persistent nearby timer
  void _stopPersistentNearbyTimer() {
    _nearbyTimer?.cancel();
    _nearbyTimer = null;
    print('Stopped persistent nearby timer');
  }

  /// Move to next city streamer
  Future<void> _moveToNextCityStreamer(String cityId) async {
    // Stop the current timer before moving to next user
    _cityTimer?.cancel();
    _cityTimer = null;
    
    final queueUsers = await getCityQueueUsers(cityId).first;
    
    if (queueUsers.isNotEmpty) {
      final nextUser = queueUsers.first;
      final userName = nextUser['name'] as String?;
      final displayName = (userName != null && userName.isNotEmpty) ? userName : "Unknown User";
      
      await setCityUserAsLive(cityId, nextUser['userId'], displayName);
      print('Moved to next city streamer: $displayName');
    } else {
      await endCityLiveSession(cityId);
      print('No users in city queue, ended live session');
    }
    
    // Reset timer for next user
    await resetCityTimer(cityId);
  }

  // ===== VLR QUEUE METHODS =====
  
  /// Get VLR queue users
  Stream<List<Map<String, dynamic>>> getVLRQueueUsers(String roomId) {
    return _firestore.collection('vlr_queue_$roomId')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Set VLR user as live
  Future<void> setVLRUserAsLive(String roomId, String userId, String userName) async {
    // Remove user from VLR queue
    final queueDoc = await _firestore.collection('vlr_queue_$roomId')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueDoc.docs.isNotEmpty) {
      await queueDoc.docs.first.reference.delete();
    }

    // Clear any existing VLR live users
    final liveUsers = await _firestore.collection('vlr_live_users_$roomId')
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }

    // Set new VLR live user
    await _firestore.collection('vlr_live_users_$roomId').add({
      'userId': userId,
      'name': userName,
      'isLive': true,
      'startTime': FieldValue.serverTimestamp(),
    });
    
    // Activate the timer when a user becomes live
    await updateVLRTimer(roomId, 20, true);
    
    // Start the persistent timer
    _startPersistentVLRTimer(roomId);
  }

  /// End VLR live session
  Future<void> endVLRLiveSession(String roomId) async {
    final liveUsers = await _firestore.collection('vlr_live_users_$roomId')
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }
    
    // Deactivate the timer when live session ends
    await updateVLRTimer(roomId, 20, false);
  }

  /// Get VLR timer
  Stream<Map<String, dynamic>?> getVLRTimer(String roomId) {
    return _firestore.collection('vlr_timer_$roomId').doc('current').snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Initialize VLR timer
  Future<void> initializeVLRTimer(String roomId) async {
    await _firestore.collection('vlr_timer_$roomId').doc('current').set({
      'countdown': 20,
      'isActive': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Update VLR timer
  Future<void> updateVLRTimer(String roomId, int countdown, bool isActive) async {
    await _firestore.collection('vlr_timer_$roomId').doc('current').update({
      'countdown': countdown,
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Reset VLR timer
  Future<void> resetVLRTimer(String roomId) async {
    await _firestore.collection('vlr_timer_$roomId').doc('current').update({
      'countdown': 20,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    
    // Start the persistent timer
    _startPersistentVLRTimer(roomId);
  }

  /// Start persistent VLR timer
  void _startPersistentVLRTimer(String roomId) {
    // Use separate VLR timer variable to avoid conflicts with city timer
    _vlrTimer?.cancel();
    print('Starting persistent VLR timer for room: $roomId');
    
    _vlrTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (_isDisposed) {
          timer.cancel();
          _vlrTimer = null;
          return;
        }
        
        // Get current timer data
        final timerData = await getVLRTimer(roomId).first;
        if (timerData != null) {
          final countdown = timerData['countdown'] ?? 20;
          final isActive = timerData['isActive'] ?? false;
          
          if (isActive) {
            final newCountdown = countdown - 1;
            print('Persistent VLR timer - Decrementing to: $newCountdown');
            
            if (newCountdown <= 0) {
              // Timer finished, move to next user
              print('Persistent VLR timer finished, moving to next streamer');
              timer.cancel();
              _vlrTimer = null;
              await _moveToNextVLRStreamer(roomId);
            } else {
              // Update the timer in Firestore
              await updateVLRTimer(roomId, newCountdown, true);
            }
          } else {
            print('Persistent VLR timer is not active, stopping');
            timer.cancel();
            _vlrTimer = null;
          }
        }
      } catch (e) {
        print('Error in persistent VLR timer: $e');
        timer.cancel();
        _vlrTimer = null;
      }
    });
  }

  /// Move to next VLR streamer
  Future<void> _moveToNextVLRStreamer(String roomId) async {
    // Stop the current timer before moving to next user
    _vlrTimer?.cancel();
    _vlrTimer = null;
    
    final queueUsers = await getVLRQueueUsers(roomId).first;
    
    if (queueUsers.isNotEmpty) {
      final nextUser = queueUsers.first;
      final userName = nextUser['name'] as String?;
      final displayName = (userName != null && userName.isNotEmpty) ? userName : "Unknown User";
      
      await setVLRUserAsLive(roomId, nextUser['userId'], displayName);
      print('Moved to next VLR streamer: $displayName');
      // setVLRUserAsLive already resets the timer and starts the persistent timer
    } else {
      await endVLRLiveSession(roomId);
      print('No users in VLR queue, ended live session');
    }
  }

  /// Ensure persistent VLR timer is running for a specific room
  Future<void> ensurePersistentVLRTimerRunning(String roomId) async {
    try {
      // Check if there's a live user
      final liveUser = await getVLRLiveUser(roomId).first;
      final hasLiveUser = liveUser != null;
      
      if (hasLiveUser) {
        // Check if timer exists and is active
        final timerData = await getVLRTimer(roomId).first;
        if (timerData != null) {
          final isActive = timerData['isActive'] ?? false;
          if (!isActive) {
            print('VLR Timer exists but not active, activating it for live user');
            await updateVLRTimer(roomId, timerData['countdown'] ?? 20, true);
            _startPersistentVLRTimer(roomId);
          } else {
            print('VLR Timer is already active, ensuring persistent timer is running');
            // Ensure the persistent timer is running without resetting
            _startPersistentVLRTimer(roomId);
          }
        } else {
          print('No VLR timer found, creating new timer for live user');
          await resetVLRTimer(roomId);
        }
      } else {
        print('No live VLR user, timer will be started when user becomes live');
      }
    } catch (e) {
      print('Error ensuring persistent VLR timer: $e');
    }
  }

  // ===== NEARBY QUEUE METHODS =====
  
  /// Get nearby queue users
  Stream<List<Map<String, dynamic>>> getNearbyQueueUsers(String locationId) {
    return _firestore.collection('nearby_queue_$locationId')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Set nearby user as live
  Future<void> setNearbyUserAsLive(String locationId, String userId, String userName) async {
    // Remove user from nearby queue
    final queueDoc = await _firestore.collection('nearby_queue_$locationId')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueDoc.docs.isNotEmpty) {
      await queueDoc.docs.first.reference.delete();
    }

    // Clear any existing nearby live users
    final liveUsers = await _firestore.collection('nearby_live_users_$locationId')
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }

    // Set new nearby live user
    await _firestore.collection('nearby_live_users_$locationId').add({
      'userId': userId,
      'name': userName,
      'isLive': true,
      'startTime': FieldValue.serverTimestamp(),
    });
    
    // Activate the timer when a user becomes live
    await updateNearbyTimer(locationId, 20, true);
    
    // Start the persistent timer
    _startPersistentNearbyTimer(locationId);
  }

  /// End nearby live session
  Future<void> endNearbyLiveSession(String locationId) async {
    final liveUsers = await _firestore.collection('nearby_live_users_$locationId')
        .where('isLive', isEqualTo: true)
        .get();

    for (var doc in liveUsers.docs) {
      await doc.reference.update({'isLive': false});
    }
    
    // Deactivate the timer when live session ends
    await updateNearbyTimer(locationId, 20, false);
  }

  /// Get nearby timer
  Stream<Map<String, dynamic>?> getNearbyTimer(String locationId) {
    return _firestore.collection('nearby_timer_$locationId').doc('current').snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Initialize nearby timer
  Future<void> initializeNearbyTimer(String locationId) async {
    await _firestore.collection('nearby_timer_$locationId').doc('current').set({
      'countdown': 20,
      'isActive': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Update nearby timer
  Future<void> updateNearbyTimer(String locationId, int countdown, bool isActive) async {
    await _firestore.collection('nearby_timer_$locationId').doc('current').update({
      'countdown': countdown,
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Reset nearby timer
  Future<void> resetNearbyTimer(String locationId) async {
    await _firestore.collection('nearby_timer_$locationId').doc('current').update({
      'countdown': 20,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    
    // Start the persistent timer
    _startPersistentNearbyTimer(locationId);
  }

  /// Start persistent nearby timer
  void _startPersistentNearbyTimer(String locationId) {
    _nearbyTimer?.cancel();
    print('Starting persistent nearby timer for location: $locationId');
    
    _nearbyTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (_isDisposed) {
          timer.cancel();
          _nearbyTimer = null;
          return;
        }
        
        // Get current timer data
        final timerData = await getNearbyTimer(locationId).first;
        if (timerData != null) {
          final countdown = timerData['countdown'] ?? 20;
          final isActive = timerData['isActive'] ?? false;
          
          if (isActive) {
            final newCountdown = countdown - 1;
            print('Persistent nearby timer - Decrementing to: $newCountdown');
            
            if (newCountdown <= 0) {
              // Timer finished, move to next user
              print('Persistent nearby timer finished, moving to next streamer');
              timer.cancel();
              _nearbyTimer = null;
              await _moveToNextNearbyStreamer(locationId);
            } else {
              // Update the timer in Firestore
              await updateNearbyTimer(locationId, newCountdown, true);
            }
          } else {
            print('Persistent nearby timer is not active, stopping');
            timer.cancel();
            _nearbyTimer = null;
          }
        }
      } catch (e) {
        print('Error in persistent nearby timer: $e');
        timer.cancel();
        _nearbyTimer = null;
      }
    });
  }

  /// Move to next nearby streamer
  Future<void> _moveToNextNearbyStreamer(String locationId) async {
    // Stop the current timer before moving to next user
    _nearbyTimer?.cancel();
    _nearbyTimer = null;
    
    final queueUsers = await getNearbyQueueUsers(locationId).first;
    
    if (queueUsers.isNotEmpty) {
      final nextUser = queueUsers.first;
      final userName = nextUser['name'] as String?;
      final displayName = (userName != null && userName.isNotEmpty) ? userName : "Unknown User";
      
      await setNearbyUserAsLive(locationId, nextUser['userId'], displayName);
      print('Moved to next nearby streamer: $displayName');
      // setNearbyUserAsLive already starts the persistent timer
    } else {
      await endNearbyLiveSession(locationId);
      print('No users in nearby queue, ended live session');
    }
  }

  // ===== CITY QUEUE JOIN/LEAVE METHODS =====
  
  /// Join city queue
  Future<void> joinCityQueue(String cityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found for city queue');
        return;
      }

      final uid = user.uid;
      
      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Joining city queue - UID: $uid, Name: $userName');

      // Stop any other active timers to prevent conflicts
      _stopPersistentSpotlightTimer();
      _stopPersistentVLRTimer();
      _stopPersistentNearbyTimer();

      // Clean up any existing users with empty names in the queue
      await _cleanupEmptyNamesInCityQueue(cityId);

      // Check if there's already a live user
      final liveUsers = await _firestore.collection('city_live_users_$cityId')
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();

      if (liveUsers.docs.isEmpty) {
        // No live user, start the timer and make this user live
        await _firestore.collection('city_queue_$cityId').doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Initialize timer if it doesn't exist
        await initializeCityTimer(cityId);
        
        // Set this user as live immediately (this will start the persistent timer)
        await setCityUserAsLive(cityId, uid, userName);
        
        print('Started city queue with user: $userName as live');
      } else {
        // There's already a live user, just add to queue
        await _firestore.collection('city_queue_$cityId').doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        print('Added user to city queue: $userName');
      }
      
      print('Successfully joined city queue for user: $uid with name: $userName');
    } catch (e) {
      print('Error joining city queue: $e');
    }
  }

  /// Clean up users with empty names in city queue
  Future<void> _cleanupEmptyNamesInCityQueue(String cityId) async {
    try {
      final queueDocs = await _firestore.collection('city_queue_$cityId').get();
      for (var doc in queueDocs.docs) {
        final data = doc.data();
        final name = data['name'] as String?;
        final userId = data['userId'] as String?;
        
        if (name == null || name.isEmpty || userId == null) {
          // Remove users with empty names or missing userId
          await doc.reference.delete();
          print('Cleaned up user with empty name in city queue: ${doc.id}');
        }
      }
    } catch (e) {
      print('Error cleaning up empty names in city queue: $e');
    }
  }

  /// Leave city queue
  Future<void> leaveCityQueue(String cityId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('city_queue_$cityId').doc(user.uid).delete();
  }

  /// Get current user's city queue status
  Stream<Map<String, dynamic>?> getCurrentUserCityQueueStatus(String cityId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('city_queue_$cityId').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get city live user
  Stream<Map<String, dynamic>?> getCityLiveUser(String cityId) {
    return _firestore.collection('city_live_users_$cityId')
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  // ===== VLR QUEUE JOIN/LEAVE METHODS =====
  
  /// Join VLR queue
  Future<void> joinVLRQueue(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      
      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Joining VLR queue for room: $roomId, user: $userName');

      // Stop any other active timers to prevent conflicts
      _stopPersistentSpotlightTimer();
      _stopPersistentCityTimer();
      _stopPersistentNearbyTimer();

      // Check if there's already a live user
      final liveUsers = await _firestore.collection('vlr_live_users_$roomId')
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();

      if (liveUsers.docs.isEmpty) {
        // No live user, start the timer and make this user live
        await _firestore.collection('vlr_queue_$roomId').doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Initialize timer if it doesn't exist
        await initializeVLRTimer(roomId);
        
        // Set this user as live immediately (this will start the persistent timer)
        await setVLRUserAsLive(roomId, uid, userName);
        
        print('Started VLR queue with user: $userName as live');
      } else {
        // There's already a live user, just add to queue
        await _firestore.collection('vlr_queue_$roomId').doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        print('Added user to VLR queue: $userName');
      }
    } catch (e) {
      print('Error joining VLR queue: $e');
    }
  }

  /// Leave VLR queue
  Future<void> leaveVLRQueue(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('vlr_queue_$roomId').doc(user.uid).delete();
  }

  /// Get current user's VLR queue status
  Stream<Map<String, dynamic>?> getCurrentUserVLRQueueStatus(String roomId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('vlr_queue_$roomId').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get VLR live user
  Stream<Map<String, dynamic>?> getVLRLiveUser(String roomId) {
    return _firestore.collection('vlr_live_users_$roomId')
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  // ===== NEARBY QUEUE JOIN/LEAVE METHODS =====
  
  /// Join nearby queue
  Future<void> joinNearbyQueue(String locationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      
      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Joining nearby queue for location: $locationId, user: $userName');

      // Stop any other active timers to prevent conflicts
      _stopPersistentSpotlightTimer();
      _stopPersistentVLRTimer();
      _stopPersistentCityTimer();

      // Check if there's already a live user
      final liveUsers = await _firestore.collection('nearby_live_users_$locationId')
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();

      if (liveUsers.docs.isEmpty) {
        // No live user, start the timer and make this user live
        await _firestore.collection('nearby_queue_$locationId').doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Initialize timer if it doesn't exist
        await initializeNearbyTimer(locationId);
        
        // Set this user as live immediately (this will start the persistent timer)
        await setNearbyUserAsLive(locationId, uid, userName);
        
        print('Started nearby queue with user: $userName as live');
      } else {
        // There's already a live user, just add to queue
        await _firestore.collection('nearby_queue_$locationId').doc(uid).set({
          'userId': uid,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        print('Added user to nearby queue: $userName');
      }
    } catch (e) {
      print('Error joining nearby queue: $e');
    }
  }

  /// Leave nearby queue
  Future<void> leaveNearbyQueue(String locationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('nearby_queue_$locationId').doc(user.uid).delete();
  }

  /// Get current user's nearby queue status
  Stream<Map<String, dynamic>?> getCurrentUserNearbyQueueStatus(String locationId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('nearby_queue_$locationId').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get nearby live user
  Stream<Map<String, dynamic>?> getNearbyLiveUser(String locationId) {
    return _firestore.collection('nearby_live_users_$locationId')
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Initialize and start persistent timers
  Future<void> initializePersistentTimers() async {
    print('Initializing persistent timers');
    // Initialize spotlight timer
    final spotlightTimerData = await getSpotlightTimer().first;
    if (spotlightTimerData != null) {
      final isActive = spotlightTimerData['isActive'] ?? false;
      if (isActive && _spotlightTimer == null) {
        _startPersistentSpotlightTimer();
      }
    }
    
    // Initialize city timers (for all cities)
    // This would need to be called for each city when needed
    
    // Initialize nearby timer (this would need locationId)
    // For now, we'll skip nearby timer initialization as it requires locationId
  }

  /// Start persistent timers for any existing live sessions
  Future<void> startPersistentTimersForExistingSessions() async {
    print('Starting persistent timers for existing live sessions');
    try {
      // Check for existing spotlight live sessions
      final spotlightLiveUser = await getCurrentLiveUser().first;
      if (spotlightLiveUser != null) {
        print('Found existing spotlight live user, ensuring timer is running');
        await ensurePersistentSpotlightTimerRunning();
      }
      // Check for existing VLR live sessions (add your actual room IDs)
      final vlrRoomIds = ['room1', 'room2', 'room3'];
      for (final roomId in vlrRoomIds) {
        final vlrLiveUser = await getVLRLiveUser(roomId).first;
        if (vlrLiveUser != null) {
          print('Found existing VLR live user in room $roomId, ensuring timer is running');
          await ensurePersistentVLRTimerRunning(roomId);
        }
      }
      // Check for existing city live sessions (add your actual city IDs)
      final cityIds = ['los_angeles', 'new_york', 'atlanta', 'chicago', 'miami'];
      for (final cityId in cityIds) {
        final cityLiveUser = await getCityLiveUser(cityId).first;
        if (cityLiveUser != null) {
          print('Found existing city live user in $cityId, ensuring timer is running');
          await ensureCityTimerRunning(cityId);
        }
      }
      // Check for existing nearby live sessions (add your actual location IDs)
      final nearbyLocationIds = ['location1', 'location2', 'location3'];
      for (final locationId in nearbyLocationIds) {
        final nearbyLiveUser = await getNearbyLiveUser(locationId).first;
        if (nearbyLiveUser != null) {
          print('Found existing nearby live user in $locationId, ensuring timer is running');
          await ensureNearbyTimerRunning(locationId);
        }
      }
    } catch (e) {
      print('Error starting persistent timers for existing sessions: $e');
    }
  }

  /// Ensure persistent city timer is running for a specific city
  Future<void> ensureCityTimerRunning(String cityId) async {
    // Check if there's a live user for this city
    final liveUser = await getCityLiveUser(cityId).first;
    if (liveUser != null) {
      // Check if timer exists and is active
      final timerData = await getCityTimer(cityId).first;
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        if (isActive && _cityTimer == null) {
          print('Ensuring persistent city timer is running for city: $cityId');
          _startPersistentCityTimer(cityId);
        }
      }
    }
  }

  /// Ensure persistent nearby timer is running for a specific location
  Future<void> ensureNearbyTimerRunning(String locationId) async {
    try {
      // Check if there's a live user
      final liveUser = await getNearbyLiveUser(locationId).first;
      final hasLiveUser = liveUser != null;
      
      if (hasLiveUser) {
        // Check if timer exists and is active
        final timerData = await getNearbyTimer(locationId).first;
        if (timerData != null) {
          final isActive = timerData['isActive'] ?? false;
          if (!isActive) {
            print('Nearby Timer exists but not active, activating it for live user');
            await updateNearbyTimer(locationId, timerData['countdown'] ?? 20, true);
            _startPersistentNearbyTimer(locationId);
          } else if (_nearbyTimer == null) {
            print('Nearby Timer is active but persistent timer not running, starting it');
            _startPersistentNearbyTimer(locationId);
          }
        } else {
          print('No nearby timer found, creating new timer for live user');
          await resetNearbyTimer(locationId);
        }
      } else {
        print('No nearby live user, timer will be started when user becomes live');
      }
    } catch (e) {
      print('Error ensuring persistent nearby timer: $e');
    }
  }

  /// Stop all persistent timers
  void stopAllPersistentTimers() {
    _stopPersistentSpotlightTimer();
    _stopPersistentCityTimer();
    _stopPersistentNearbyTimer();
    _stopPersistentVLRTimer();
  }

  /// Dispose all timers (call when app is closing)
  void dispose() {
    _isDisposed = true;
    stopAllPersistentTimers();
  }

  // Helper: Check if current user is the live user
  Future<bool> isCurrentUserLiveUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final liveUser = await getCurrentLiveUser().first;
    return liveUser != null && liveUser['userId'] == user.uid;
  }
} 