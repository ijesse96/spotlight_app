import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_queue_controller.dart';
import 'queue_config.dart';
import 'unified_timer_service.dart';

/// VLR queue controller implementation
class VLRQueueController extends BaseQueueController {
  final QueueConfig _config;
  final UnifiedTimerService _timerService = UnifiedTimerService();

  VLRQueueController(this._config);

  @override
  String get queueId => _config.id;
  
  @override
  String get queueType => _config.type.name;
  
  @override
  int get defaultDuration => _config.defaultDuration;
  
  @override
  String get collectionPrefix => _config.collectionPrefix;

  @override
  CollectionReference get queueCollection => firestore.collection(_config.queueCollectionName);
  
  @override
  CollectionReference get liveUserCollection => firestore.collection(_config.liveUserCollectionName);
  
  @override
  CollectionReference get timerCollection => firestore.collection(_config.timerCollectionName);

  @override
  Future<void> joinQueue() async {
    if (!isAuthenticated) {
      throw Exception('User must be authenticated to join queue');
    }

    final userId = currentUserId!;
    final displayName = await getUserDisplayName();

    print('🔄 [VLR_QUEUE] Joining VLR queue: ${_config.displayName}');
    print('✅ [VLR_QUEUE] User: $displayName');

    try {
      // Remove user from all other queues first
      await _removeUserFromAllQueues(userId);

      // Add user to VLR queue
      await queueCollection.doc(userId).set({
        'id': userId,
        'displayName': displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'isLive': false,
        'photoURL': auth.currentUser?.photoURL,
        'roomId': _config.id,
        'roomName': _config.displayName,
        'queueType': 'vlr',
      });

      print('✅ [VLR_QUEUE] Successfully joined VLR queue: ${_config.displayName}');
    } catch (e) {
      print('❌ [VLR_QUEUE] Error joining VLR queue: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveQueue() async {
    if (!isAuthenticated) return;

    final userId = currentUserId!;
    print('🔄 [VLR_QUEUE] Leaving VLR queue: ${_config.displayName}');

    try {
      // Remove from VLR queue
      await queueCollection.doc(userId).delete();
      
      // End live session if user was live
      await endLiveSession();
      
      print('✅ [VLR_QUEUE] Successfully left VLR queue: ${_config.displayName}');
    } catch (e) {
      print('❌ [VLR_QUEUE] Error leaving VLR queue: $e');
      rethrow;
    }
  }

  @override
  Stream<List<QueueUser>> getQueueUsers() {
    return queueCollection
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return QueueUser.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }

  @override
  Stream<QueueUser?> getCurrentLiveUser() {
    return liveUserCollection
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return QueueUser.fromMap({
          'id': doc.id,
          ...data,
        });
      }
      return null;
    });
  }

  @override
  Stream<TimerState> getTimerState() {
    return _timerService.getTimerStateStream(_config.timerId);
  }

  @override
  Future<void> setUserAsLive(String userId, String userName) async {
    print('🔄 [VLR_QUEUE] Setting user as live: $userName');

    try {
      // End any existing live session
      await endLiveSession();

      // Set new user as live
      await liveUserCollection.doc(userId).set({
        'id': userId,
        'displayName': userName,
        'isLive': true,
        'timestamp': FieldValue.serverTimestamp(),
        'photoURL': auth.currentUser?.photoURL,
        'roomId': _config.id,
        'roomName': _config.displayName,
        'queueType': 'vlr',
      });

      // Update timer with current live user
      await _timerService.setCurrentLiveUser(_config.timerId, userId, userName);

      print('✅ [VLR_QUEUE] User set as live: $userName');
    } catch (e) {
      print('❌ [VLR_QUEUE] Error making user live: $e');
      rethrow;
    }
  }

  @override
  Future<void> endLiveSession() async {
    print('🔄 [VLR_QUEUE] Ending live session');

    try {
      // Remove all live users
      final liveUsers = await liveUserCollection.where('isLive', isEqualTo: true).get();
      for (final doc in liveUsers.docs) {
        await doc.reference.delete();
      }

      // Clear timer live user
      await _timerService.clearCurrentLiveUser(_config.timerId);

      print('✅ [VLR_QUEUE] Live session ended');
    } catch (e) {
      print('❌ [VLR_QUEUE] Error ending live session: $e');
      rethrow;
    }
  }

  @override
  Future<void> moveToNextUser() async {
    print('🔄 [VLR_QUEUE] Moving to next user');

    try {
      // Get queue users
      final queueSnapshot = await queueCollection
          .orderBy('timestamp', descending: false)
          .get();

      if (queueSnapshot.docs.isEmpty) {
        print('ℹ️ [VLR_QUEUE] No users in queue');
        await endLiveSession();
        return;
      }

      // Get the first user in queue
      final nextUserDoc = queueSnapshot.docs.first;
      final nextUserData = nextUserDoc.data() as Map<String, dynamic>;
      final nextUserId = nextUserDoc.id;
      final nextUserName = nextUserData['displayName'] ?? 'Unknown User';

      // Remove user from queue
      await nextUserDoc.reference.delete();

      // Set as live
      await setUserAsLive(nextUserId, nextUserName);

      // Start timer
      await startTimer();

      print('✅ [VLR_QUEUE] Moved to next user: $nextUserName');
    } catch (e) {
      print('❌ [VLR_QUEUE] Error moving to next user: $e');
      rethrow;
    }
  }

  @override
  Future<void> startTimer() async {
    print('🕐 [VLR_QUEUE] Starting timer');
    await _timerService.startTimer(_config.timerId, defaultDuration);
  }

  @override
  Future<void> stopTimer() async {
    print('⏹️ [VLR_QUEUE] Stopping timer');
    await _timerService.stopTimer(_config.timerId);
  }

  @override
  Future<void> resetTimer() async {
    print('🔄 [VLR_QUEUE] Resetting timer');
    await _timerService.resetTimer(_config.timerId, defaultDuration);
  }

  /// Remove user from all queues (helper method)
  Future<void> _removeUserFromAllQueues(String userId) async {
    try {
      // Remove from VLR queue
      await queueCollection.doc(userId).delete();
      
      // Remove from live users
      await liveUserCollection.doc(userId).delete();
      
      print('🔄 [VLR_QUEUE] Removed user $userId from all queues');
    } catch (e) {
      // Ignore errors if user wasn't in queue
      print('ℹ️ [VLR_QUEUE] User not in queue or already removed');
    }
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStats() async {
    try {
      final queueCount = await queueCollection.count().get();
      final liveCount = await liveUserCollection.where('isLive', isEqualTo: true).count().get();
      
      return {
        'queueSize': queueCount.count,
        'liveUsers': liveCount.count,
        'timerActive': _timerService.isTimerActive(_config.timerId),
        'timerState': _timerService.getCurrentTimerState(_config.timerId),
        'roomId': _config.id,
        'roomName': _config.displayName,
        'queueType': 'vlr',
      };
    } catch (e) {
      print('❌ [VLR_QUEUE] Error getting queue stats: $e');
      return {};
    }
  }

  /// Check if user is in queue
  Future<bool> isUserInQueue(String userId) async {
    try {
      final doc = await queueCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is live
  Future<bool> isUserLive(String userId) async {
    try {
      final doc = await liveUserCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isLive'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get VLR-specific information
  String get roomId => _config.id;
  String get roomName => _config.displayName;
  String get vlrQueueType => 'vlr';
} 