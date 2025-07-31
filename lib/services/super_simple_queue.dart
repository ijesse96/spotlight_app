import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'debug_user_service.dart';

/// Super simple queue user
class SuperSimpleUser {
  final String id;
  final String name;
  final DateTime joinedAt;
  final bool isLive;

  SuperSimpleUser({
    required this.id,
    required this.name,
    required this.joinedAt,
    this.isLive = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isLive': isLive,
  };

  factory SuperSimpleUser.fromMap(Map<String, dynamic> map) {
    DateTime joinedAt;
    if (map['joinedAt'] == null) {
      joinedAt = DateTime.now();
    } else if (map['joinedAt'] is Timestamp) {
      joinedAt = (map['joinedAt'] as Timestamp).toDate();
    } else {
      joinedAt = DateTime.now();
    }
    
    return SuperSimpleUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      joinedAt: joinedAt,
      isLive: map['isLive'] ?? false,
    );
  }
}

/// Super simple queue service - NO COMPLEX TIMERS
class SuperSimpleQueue {
  static final SuperSimpleQueue _instance = SuperSimpleQueue._internal();
  factory SuperSimpleQueue() => _instance;
  SuperSimpleQueue._internal();

  // Global timer instance to prevent multiple timers
  static Timer? _globalTimer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final DebugUserService _debugUserService = DebugUserService();

  // Collections
  CollectionReference get _queueCollection => _firestore.collection('super_simple_queue');
  CollectionReference get _timerCollection => _firestore.collection('super_simple_timer');



  // Streams
  Stream<List<SuperSimpleUser>> get queueStream => _queueCollection
      .orderBy('joinedAt')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SuperSimpleUser.fromMap(doc.data() as Map<String, dynamic>))
          .toList());

  Stream<int> get timerStream => _timerCollection
      .doc('timer')
      .snapshots()
      .map((doc) => doc.exists ? ((doc.data() as Map<String, dynamic>)?['seconds'] ?? 0) : 0);

  // Join queue
  Future<void> joinQueue() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Debug user data first
    await _debugUserService.debugUserData();
    
    // Get the best available display name
    final name = await _debugUserService.getBestDisplayName();

    print('🔄 [SUPER_SIMPLE] User $name joining queue');

    await _queueCollection.doc(user.uid).set({
      'id': user.uid,
      'name': name,
      'joinedAt': FieldValue.serverTimestamp(),
      'isLive': false,
    });

    // Check if first user
    final queueSnapshot = await _queueCollection.orderBy('joinedAt').get();
    if (queueSnapshot.docs.length == 1) {
      print('🔄 [SUPER_SIMPLE] First user, going live automatically');
      await goLive();
    }
  }

  // Leave queue
  Future<void> leaveQueue() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if user is currently live
    final userDoc = await _queueCollection.doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final isLive = userData['isLive'] ?? false;
      
      if (isLive) {
        print('🔄 [SUPER_SIMPLE] Live user left queue, rotating to next user');
        await rotateToNext();
        return;
      }
    }

    await _queueCollection.doc(user.uid).delete();
    print('🔄 [SUPER_SIMPLE] User left queue');
  }

  // Go live
  Future<void> goLive() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Set user as live
    await _queueCollection.doc(user.uid).update({'isLive': true});

    // Start simple timer
    await _timerCollection.doc('timer').set({'seconds': 30});

    // Start countdown after a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _startSimpleCountdown();
    });

    print('🔄 [SUPER_SIMPLE] User went live');
  }

  // Rotate to next user
  Future<void> rotateToNext() async {
    print('🔄 [SUPER_SIMPLE] Manual rotation triggered');
    
    // Cancel any existing timer first to prevent double rotation
    _globalTimer?.cancel();
    _globalTimer = null;
    
    final queueSnapshot = await _queueCollection.orderBy('joinedAt').get();
    final users = queueSnapshot.docs
        .map((doc) => SuperSimpleUser.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (users.isEmpty) {
      await _timerCollection.doc('timer').set({'seconds': 0});
      return;
    }

    // Find current live user
    final currentLiveIndex = users.indexWhere((u) => u.isLive);
    
    if (currentLiveIndex == -1) {
      // No live user, set first as live
      await _queueCollection.doc(users[0].id).update({'isLive': true});
      await _timerCollection.doc('timer').set({'seconds': 30});
      
      // Start new countdown after a small delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _startSimpleCountdown();
      });
      return;
    }

    // End current live session and remove from queue
    await _queueCollection.doc(users[currentLiveIndex].id).delete();
    print('🔄 [SUPER_SIMPLE] Removed ${users[currentLiveIndex].name} from queue after live session');

    // Find next user
    final nextIndex = (currentLiveIndex + 1) % users.length;
    final nextUser = users[nextIndex];

    // Set next user as live
    await _queueCollection.doc(nextUser.id).update({'isLive': true});

    // Reset timer
    await _timerCollection.doc('timer').set({'seconds': 30});
    
    // Start new countdown after a small delay to ensure previous timer is cleaned up
    Future.delayed(const Duration(milliseconds: 100), () {
      _startSimpleCountdown();
    });
  }

  // Super simple countdown - NO COMPLEX LOGIC
  void _startSimpleCountdown() {
    // Cancel any existing global timer
    _globalTimer?.cancel();
    _globalTimer = null;
    
    print('🕐 [SUPER_SIMPLE] Starting simple countdown');
    
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final timerDoc = await _timerCollection.doc('timer').get();
        if (!timerDoc.exists) {
          timer.cancel();
          _globalTimer = null;
          return;
        }

        final currentSeconds = (timerDoc.data() as Map<String, dynamic>)?['seconds'] ?? 0;
        print('🕐 [SUPER_SIMPLE] Timer: ${currentSeconds}s');

        if (currentSeconds <= 0) {
          print('⏰ [SUPER_SIMPLE] Timer finished');
          timer.cancel();
          _globalTimer = null;
          await rotateToNext();
          return;
        }

        await _timerCollection.doc('timer').update({
          'seconds': currentSeconds - 1,
        });
      } catch (e) {
        print('❌ [SUPER_SIMPLE] Timer error: $e');
        timer.cancel();
        _globalTimer = null;
      }
    });
  }

  // Check if user is in queue
  Future<bool> isUserInQueue() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _queueCollection.doc(user.uid).get();
    return doc.exists;
  }

  // Stream to check if user is in queue
  Stream<bool> get userInQueueStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _queueCollection.doc(user.uid).snapshots().map((doc) => doc.exists);
  }

  // Get current live user stream
  Stream<SuperSimpleUser?> get liveUserStream => _queueCollection
      .where('isLive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        return SuperSimpleUser.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      });

  // Get current live user (for backward compatibility)
  Future<SuperSimpleUser?> getCurrentLiveUser() async {
    final liveUserDoc = await _queueCollection.where('isLive', isEqualTo: true).limit(1).get();
    if (liveUserDoc.docs.isEmpty) return null;
    
    return SuperSimpleUser.fromMap(liveUserDoc.docs.first.data() as Map<String, dynamic>);
  }

  // Get current user if they are in the queue
  Future<SuperSimpleUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _queueCollection.doc(user.uid).get();
    if (!doc.exists) return null;
    
    return SuperSimpleUser.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Cleanup method
  void dispose() {
    _globalTimer?.cancel();
    _globalTimer = null;
  }
} 