import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'queue/index.dart';

/// Migration service that provides the same interface as the old QueueService
/// but uses the new modular queue system internally
class QueueMigrationService {
  static final QueueMigrationService _instance = QueueMigrationService._internal();
  factory QueueMigrationService() => _instance;
  QueueMigrationService._internal();

  final UnifiedQueueService _unifiedService = UnifiedQueueService();

  // Spotlight Queue Methods (using SpotlightQueueController)
  
  /// Get current live user for spotlight queue
  Stream<Map<String, dynamic>?> getCurrentLiveUser() {
    final spotlightController = _unifiedService.spotlightQueue;
    return spotlightController.getCurrentLiveUser().map((user) {
      if (user != null) {
        return {
          'id': user.id,
          'displayName': user.displayName,
          'timestamp': user.timestamp,
          'isLive': user.isLive,
          'photoURL': user.photoURL,
        };
      }
      return null;
    });
  }

  /// Get queue users for spotlight queue
  Stream<List<Map<String, dynamic>>> getQueueUsers() {
    final spotlightController = _unifiedService.spotlightQueue;
    return spotlightController.getQueueUsers().map((users) {
      return users.map((user) => {
        'id': user.id,
        'displayName': user.displayName,
        'timestamp': user.timestamp,
        'isLive': user.isLive,
        'photoURL': user.photoURL,
      }).toList();
    });
  }

  /// Join spotlight queue
  Future<void> joinQueue() async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.joinQueue();
  }

  /// Leave spotlight queue
  Future<void> leaveQueue() async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.leaveQueue();
  }

  /// Set user as live in spotlight queue
  Future<void> setUserAsLive(String userId, String userName) async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.setUserAsLive(userId, userName);
  }

  /// End live session in spotlight queue
  Future<void> endLiveSession() async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.endLiveSession();
  }

  /// Get current user queue status for spotlight
  Stream<Map<String, dynamic>?> getCurrentUserQueueStatus() {
    final spotlightController = _unifiedService.spotlightQueue;
    return spotlightController.getQueueUsers().map((users) {
      // Find current user in queue
      for (final user in users) {
        if (user.id == _getCurrentUserId()) {
          return {
            'id': user.id,
            'displayName': user.displayName,
            'timestamp': user.timestamp,
            'isLive': user.isLive,
            'photoURL': user.photoURL,
          };
        }
      }
      return null;
    });
  }

  /// Get spotlight timer
  Stream<Map<String, dynamic>?> getSpotlightTimer() {
    final spotlightController = _unifiedService.spotlightQueue;
    return spotlightController.getTimerState().map((state) => {
      'countdown': state.remainingSeconds,
      'isActive': state.isActive,
      'currentLiveUserId': state.currentLiveUserId,
      'currentLiveUserName': state.currentLiveUserName,
    });
  }

  // City Queue Methods (using CityQueueController)

  /// Get city queue users
  Stream<List<Map<String, dynamic>>> getCityQueueUsers(String cityId) {
    final cityController = _unifiedService.getCityQueue(cityId);
    return cityController.getQueueUsers().map((users) {
      return users.map((user) => {
        'id': user.id,
        'displayName': user.displayName,
        'timestamp': user.timestamp,
        'isLive': user.isLive,
        'photoURL': user.photoURL,
        'cityId': cityId,
      }).toList();
    });
  }

  /// Join city queue
  Future<void> joinCityQueue(String cityId) async {
    final cityController = _unifiedService.getCityQueue(cityId);
    await cityController.joinQueue();
  }

  /// Leave city queue
  Future<void> leaveCityQueue(String cityId) async {
    final cityController = _unifiedService.getCityQueue(cityId);
    await cityController.leaveQueue();
  }

  /// Get current user city queue status
  Stream<Map<String, dynamic>?> getCurrentUserCityQueueStatus(String cityId) {
    final cityController = _unifiedService.getCityQueue(cityId);
    return cityController.getQueueUsers().map((users) {
      for (final user in users) {
        if (user.id == _getCurrentUserId()) {
          return {
            'id': user.id,
            'displayName': user.displayName,
            'timestamp': user.timestamp,
            'isLive': user.isLive,
            'photoURL': user.photoURL,
            'cityId': cityId,
          };
        }
      }
      return null;
    });
  }

  /// Get city live user
  Stream<Map<String, dynamic>?> getCityLiveUser(String cityId) {
    final cityController = _unifiedService.getCityQueue(cityId);
    return cityController.getCurrentLiveUser().map((user) {
      if (user != null) {
        return {
          'id': user.id,
          'displayName': user.displayName,
          'timestamp': user.timestamp,
          'isLive': user.isLive,
          'photoURL': user.photoURL,
          'cityId': cityId,
        };
      }
      return null;
    });
  }

  /// Get city timer
  Stream<Map<String, dynamic>?> getCityTimer(String cityId) {
    final cityController = _unifiedService.getCityQueue(cityId);
    return cityController.getTimerState().map((state) => {
      'countdown': state.remainingSeconds,
      'isActive': state.isActive,
      'currentLiveUserId': state.currentLiveUserId,
      'currentLiveUserName': state.currentLiveUserName,
    });
  }

  // Nearby Queue Methods (using NearbyQueueController)

  /// Get nearby queue users
  Stream<List<Map<String, dynamic>>> getNearbyQueueUsers(String locationId) {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    return nearbyController.getQueueUsers().map((users) {
      return users.map((user) => {
        'id': user.id,
        'displayName': user.displayName,
        'timestamp': user.timestamp,
        'isLive': user.isLive,
        'photoURL': user.photoURL,
        'locationId': locationId,
      }).toList();
    });
  }

  /// Join nearby queue
  Future<void> joinNearbyQueue(String locationId) async {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    await nearbyController.joinQueue();
  }

  /// Leave nearby queue
  Future<void> leaveNearbyQueue(String locationId) async {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    await nearbyController.leaveQueue();
  }

  /// Get current user nearby queue status
  Stream<Map<String, dynamic>?> getCurrentUserNearbyQueueStatus(String locationId) {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    return nearbyController.getQueueUsers().map((users) {
      for (final user in users) {
        if (user.id == _getCurrentUserId()) {
          return {
            'id': user.id,
            'displayName': user.displayName,
            'timestamp': user.timestamp,
            'isLive': user.isLive,
            'photoURL': user.photoURL,
            'locationId': locationId,
          };
        }
      }
      return null;
    });
  }

  /// Get nearby live user
  Stream<Map<String, dynamic>?> getNearbyLiveUser(String locationId) {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    return nearbyController.getCurrentLiveUser().map((user) {
      if (user != null) {
        return {
          'id': user.id,
          'displayName': user.displayName,
          'timestamp': user.timestamp,
          'isLive': user.isLive,
          'photoURL': user.photoURL,
          'locationId': locationId,
        };
      }
      return null;
    });
  }

  /// Get nearby timer
  Stream<Map<String, dynamic>?> getNearbyTimer(String locationId) {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    return nearbyController.getTimerState().map((state) => {
      'countdown': state.remainingSeconds,
      'isActive': state.isActive,
      'currentLiveUserId': state.currentLiveUserId,
      'currentLiveUserName': state.currentLiveUserName,
    });
  }

  // VLR Queue Methods (using VLRQueueController)

  /// Get VLR queue users
  Stream<List<Map<String, dynamic>>> getVLRQueueUsers(String roomId) {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    return vlrController.getQueueUsers().map((users) {
      return users.map((user) => {
        'id': user.id,
        'displayName': user.displayName,
        'timestamp': user.timestamp,
        'isLive': user.isLive,
        'photoURL': user.photoURL,
        'roomId': roomId,
      }).toList();
    });
  }

  /// Join VLR queue
  Future<void> joinVLRQueue(String roomId) async {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    await vlrController.joinQueue();
  }

  /// Leave VLR queue
  Future<void> leaveVLRQueue(String roomId) async {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    await vlrController.leaveQueue();
  }

  /// Get current user VLR queue status
  Stream<Map<String, dynamic>?> getCurrentUserVLRQueueStatus(String roomId) {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    return vlrController.getQueueUsers().map((users) {
      for (final user in users) {
        if (user.id == _getCurrentUserId()) {
          return {
            'id': user.id,
            'displayName': user.displayName,
            'timestamp': user.timestamp,
            'isLive': user.isLive,
            'photoURL': user.photoURL,
            'roomId': roomId,
          };
        }
      }
      return null;
    });
  }

  /// Get VLR live user
  Stream<Map<String, dynamic>?> getVLRLiveUser(String roomId) {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    return vlrController.getCurrentLiveUser().map((user) {
      if (user != null) {
        return {
          'id': user.id,
          'displayName': user.displayName,
          'timestamp': user.timestamp,
          'isLive': user.isLive,
          'photoURL': user.photoURL,
          'roomId': roomId,
        };
      }
      return null;
    });
  }

  /// Get VLR timer
  Stream<Map<String, dynamic>?> getVLRTimer(String roomId) {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    return vlrController.getTimerState().map((state) => {
      'countdown': state.remainingSeconds,
      'isActive': state.isActive,
      'currentLiveUserId': state.currentLiveUserId,
      'currentLiveUserName': state.currentLiveUserName,
    });
  }

  // Local Queue Methods (using LocalQueueController)

  /// Get local queue users
  Stream<List<Map<String, dynamic>>> getLocalQueueUsers(String locationId) {
    final localController = _unifiedService.getLocalQueue(locationId);
    return localController.getQueueUsers().map((users) {
      return users.map((user) => {
        'id': user.id,
        'displayName': user.displayName,
        'timestamp': user.timestamp,
        'isLive': user.isLive,
        'photoURL': user.photoURL,
        'locationId': locationId,
      }).toList();
    });
  }

  /// Join local queue
  Future<void> joinLocalQueue(String locationId) async {
    final localController = _unifiedService.getLocalQueue(locationId);
    await localController.joinQueue();
  }

  /// Leave local queue
  Future<void> leaveLocalQueue(String locationId) async {
    final localController = _unifiedService.getLocalQueue(locationId);
    await localController.leaveQueue();
  }

  /// Get current user local queue status
  Stream<Map<String, dynamic>?> getCurrentUserLocalQueueStatus(String locationId) {
    final localController = _unifiedService.getLocalQueue(locationId);
    return localController.getQueueUsers().map((users) {
      for (final user in users) {
        if (user.id == _getCurrentUserId()) {
          return {
            'id': user.id,
            'displayName': user.displayName,
            'timestamp': user.timestamp,
            'isLive': user.isLive,
            'photoURL': user.photoURL,
            'locationId': locationId,
          };
        }
      }
      return null;
    });
  }

  /// Get current local live user
  Stream<Map<String, dynamic>?> getCurrentLocalLiveUser(String locationId) {
    final localController = _unifiedService.getLocalQueue(locationId);
    return localController.getCurrentLiveUser().map((user) {
      if (user != null) {
        return {
          'id': user.id,
          'displayName': user.displayName,
          'timestamp': user.timestamp,
          'isLive': user.isLive,
          'photoURL': user.photoURL,
          'locationId': locationId,
        };
      }
      return null;
    });
  }

  /// Get local timer
  Stream<Map<String, dynamic>?> getLocalTimer(String locationId) {
    final localController = _unifiedService.getLocalQueue(locationId);
    return localController.getTimerState().map((state) => {
      'countdown': state.remainingSeconds,
      'isActive': state.isActive,
      'currentLiveUserId': state.currentLiveUserId,
      'currentLiveUserName': state.currentLiveUserName,
    });
  }

  // Helper methods

  /// Get current user ID
  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Additional methods that might be needed for compatibility
  // These can be implemented as needed

  /// Update ready status (placeholder for compatibility)
  Future<void> updateReadyStatus(bool isReady) async {
    // This method might not be needed in the new system
    // Implement if required for compatibility
  }

  /// Initialize spotlight timer (now handled by UnifiedTimerService)
  Future<void> initializeSpotlightTimer() async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.resetTimer();
  }

  /// Update spotlight timer (now handled by UnifiedTimerService)
  Future<void> updateSpotlightTimer(int countdown, bool isActive) async {
    final spotlightController = _unifiedService.spotlightQueue;
    if (isActive) {
      await spotlightController.startTimer();
    } else {
      await spotlightController.stopTimer();
    }
  }

  /// Reset spotlight timer (now handled by UnifiedTimerService)
  Future<void> resetSpotlightTimer() async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.resetTimer();
  }

  /// Move to next user in spotlight queue
  Future<void> moveToNextSpotlightStreamer() async {
    final spotlightController = _unifiedService.spotlightQueue;
    await spotlightController.moveToNextUser();
  }

  /// Move to next user in city queue
  Future<void> moveToNextCityStreamer(String cityId) async {
    final cityController = _unifiedService.getCityQueue(cityId);
    await cityController.moveToNextUser();
  }

  /// Move to next user in nearby queue
  Future<void> moveToNextNearbyStreamer(String locationId) async {
    final nearbyController = _unifiedService.getNearbyQueue(locationId);
    await nearbyController.moveToNextUser();
  }

  /// Move to next user in VLR queue
  Future<void> moveToNextVLRStreamer(String roomId) async {
    final vlrController = _unifiedService.getVLRQueue(roomId);
    await vlrController.moveToNextUser();
  }

  /// Move to next user in local queue
  Future<void> moveToNextLocalStreamer(String locationId) async {
    final localController = _unifiedService.getLocalQueue(locationId);
    await localController.moveToNextUser();
  }
} 