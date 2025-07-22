import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'profile_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileService _profileService = ProfileService();
  final GeoFlutterFire _geo = GeoFlutterFire();

  // Collection references
  CollectionReference get _localStreamsCollection => _firestore.collection('local_streams');
  CollectionReference get _citiesCollection => _firestore.collection('cities');
  CollectionReference get _verifiedRoomsCollection => _firestore.collection('verified_rooms');

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

  /// Get current user's location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get nearby users within radius (in miles)
  Stream<List<Map<String, dynamic>>> getNearbyUsers(double radiusInMiles) {
    return _geo.collection(collectionRef: _localStreamsCollection)
        .within(
          center: GeoFirePoint(0, 0), // Will be updated with actual location
          radius: radiusInMiles,
          field: 'position',
        )
        .map((snapshot) {
      return snapshot.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Get nearby users count
  Stream<int> getNearbyUsersCount(double radiusInMiles) {
    return getNearbyUsers(radiusInMiles).map((users) => users.length);
  }

  /// Update user's location in local_streams
  Future<void> updateUserLocation(Position position) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      
      // Generate a user-friendly name for anonymous users
      String userName;
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName!;
      } else {
        final shortUid = uid.length > 6 ? uid.substring(uid.length - 6) : uid;
        userName = 'User_$shortUid';
      }

      // Create GeoPoint for Firestore
      final geoPoint = _geo.point(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Update or create user location document
      await _localStreamsCollection.doc(uid).set({
        'userId': uid,
        'name': userName,
        'position': geoPoint.data,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('Updated location for user: $uid at ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  /// Get all major cities
  Stream<List<Map<String, dynamic>>> getMajorCities() {
    return _citiesCollection
        .orderBy('name')
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

  /// Get city queue users
  Stream<List<Map<String, dynamic>>> getCityQueueUsers(String cityId) {
    return _citiesCollection
        .doc(cityId)
        .collection('queue')
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

  /// Join city queue (no location restriction)
  Future<void> joinCityQueue(String cityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      
      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Joining city queue for $cityId, user: $uid, name: $userName');

      await _citiesCollection
          .doc(cityId)
          .collection('queue')
          .doc(uid)
          .set({
        'userId': uid,
        'name': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Joined city queue for $cityId, user: $uid');
    } catch (e) {
      print('Error joining city queue: $e');
    }
  }

  /// Leave city queue
  Future<void> leaveCityQueue(String cityId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _citiesCollection
        .doc(cityId)
        .collection('queue')
        .doc(user.uid)
        .delete();
  }

  /// Get verified rooms for a city
  Stream<List<Map<String, dynamic>>> getVerifiedRooms(String cityId) {
    return _verifiedRoomsCollection
        .where('cityId', isEqualTo: cityId)
        .orderBy('name')
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

  /// Check if user is within range of a verified room
  Future<bool> isUserNearVerifiedRoom(String roomId, double maxDistanceMiles) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return false;

      final roomDoc = await _verifiedRoomsCollection.doc(roomId).get();
      if (!roomDoc.exists) return false;

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final roomLocation = roomData['location'] as GeoPoint;

      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        roomLocation.latitude,
        roomLocation.longitude,
      );

      final distanceInMiles = distanceInMeters * 0.000621371; // Convert meters to miles
      return distanceInMiles <= maxDistanceMiles;
    } catch (e) {
      print('Error checking distance to verified room: $e');
      return false;
    }
  }

  /// Get verified room queue users
  Stream<List<Map<String, dynamic>>> getVerifiedRoomQueueUsers(String roomId) {
    return _verifiedRoomsCollection
        .doc(roomId)
        .collection('queue')
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

  /// Join verified room queue (with location check)
  Future<bool> joinVerifiedRoomQueue(String roomId) async {
    try {
      // Check if user is within 0.2 miles of the room
      final isNearby = await isUserNearVerifiedRoom(roomId, 0.2);
      if (!isNearby) {
        print('User is not within 0.2 miles of verified room');
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) return false;

      final uid = user.uid;
      
      // Generate a user-friendly name for anonymous users
      String userName;
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName!;
      } else {
        final shortUid = uid.length > 6 ? uid.substring(uid.length - 6) : uid;
        userName = 'User_$shortUid';
      }

      await _verifiedRoomsCollection
          .doc(roomId)
          .collection('queue')
          .doc(uid)
          .set({
        'userId': uid,
        'name': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Joined verified room queue for $roomId, user: $uid');
      return true;
    } catch (e) {
      print('Error joining verified room queue: $e');
      return false;
    }
  }

  /// Join verified room queue for testing (bypasses location check)
  Future<bool> joinVerifiedRoomQueueForTesting(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final uid = user.uid;
      
      // Generate a user-friendly name for anonymous users
      String userName;
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName!;
      } else {
        final shortUid = uid.length > 6 ? uid.substring(uid.length - 6) : uid;
        userName = 'User_$shortUid';
      }

      await _verifiedRoomsCollection
          .doc(roomId)
          .collection('queue')
          .doc(uid)
          .set({
        'userId': uid,
        'name': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Joined verified room queue for testing - $roomId, user: $uid');
      return true;
    } catch (e) {
      print('Error joining verified room queue for testing: $e');
      return false;
    }
  }

  /// Leave verified room queue
  Future<void> leaveVerifiedRoomQueue(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _verifiedRoomsCollection
        .doc(roomId)
        .collection('queue')
        .doc(user.uid)
        .delete();
  }

  /// Get current user's city queue status
  Stream<Map<String, dynamic>?> getCurrentUserCityQueueStatus(String cityId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _citiesCollection
        .doc(cityId)
        .collection('queue')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Get current user's verified room queue status
  Stream<Map<String, dynamic>?> getCurrentUserVerifiedRoomQueueStatus(String roomId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _verifiedRoomsCollection
        .doc(roomId)
        .collection('queue')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    });
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location permission is denied forever
  Future<bool> isLocationPermissionDeniedForever() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings for location permission
  Future<void> openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Discover nearby queue clusters
  Stream<List<Map<String, dynamic>>> discoverNearbyQueues() {
    return Stream.periodic(const Duration(seconds: 10), (_) async {
      try {
        final position = await getCurrentLocation();
        if (position == null) return <Map<String, dynamic>>[];

        final List<Map<String, dynamic>> queueClusters = [];

        // 1. Find nearby users in local_streams (5-10 mile radius)
        final nearbyUsers = await _getNearbyUsers(position, 10.0); // 10 mile radius
        
        // Always show nearby queue if there are users in the area, even if queue is empty
        if (nearbyUsers.isNotEmpty) {
          // Use a more stable locationId based on rounded coordinates (less sensitive to small movements)
          final locationId = 'nearby_${(position.latitude * 100).round() / 100}_${(position.longitude * 100).round() / 100}';
          
          // Get the actual queue count for this location
          final queueUsers = await _firestore.collection('nearby_queue_$locationId').get();
          final queueCount = queueUsers.docs.length;
          
          queueClusters.add({
            'type': 'nearby_users',
            'locationId': locationId,
            'label': '$queueCount people in queue',
            'count': queueCount,
            'users': nearbyUsers,
            'distance': '5-10 miles',
            'priority': 1, // Highest priority
          });
        } else {
          // If no nearby users found, still show a nearby queue option for discovery
          final locationId = 'nearby_${(position.latitude * 100).round() / 100}_${(position.longitude * 100).round() / 100}';
          
          // Check if there's an existing queue at this location
          final queueUsers = await _firestore.collection('nearby_queue_$locationId').get();
          final queueCount = queueUsers.docs.length;
          
          if (queueCount > 0) {
            // Show existing queue even if no nearby users currently
            queueClusters.add({
              'type': 'nearby_users',
              'locationId': locationId,
              'label': '$queueCount people in queue',
              'count': queueCount,
              'users': [],
              'distance': '5-10 miles',
              'priority': 1,
            });
          }
        }

        // 2. Find nearby verified rooms (0.2 mile radius)
        final nearbyRooms = await _getNearbyVerifiedRooms(position, 0.2);
        for (final room in nearbyRooms) {
          // Always show verified room queues, even if empty
          final roomQueueUsers = await getVerifiedRoomQueueUsers(room['id']).first;
          final queueCount = roomQueueUsers.length;
          
          queueClusters.add({
            'type': 'verified_room',
            'roomId': room['id'],
            'roomName': room['name'],
            'label': '$queueCount users near ${room['name']}',
            'count': queueCount,
            'users': roomQueueUsers,
            'distance': '0.2 miles',
            'priority': 2, // Second priority
          });
        }

        // Sort by priority (nearby users first, then verified rooms)
        queueClusters.sort((a, b) => a['priority'].compareTo(b['priority']));

        return queueClusters;
      } catch (e) {
        print('Error discovering nearby queues: $e');
        return <Map<String, dynamic>>[];
      }
    }).asyncMap((future) => future);
  }

  /// Get nearby users within specified radius
  Future<List<Map<String, dynamic>>> _getNearbyUsers(Position position, double radiusInMiles) async {
    try {
      final geoPoint = _geo.point(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final snapshot = await _geo.collection(collectionRef: _localStreamsCollection)
          .within(
            center: geoPoint,
            radius: radiusInMiles,
            field: 'position',
          )
          .first;

      return snapshot.map<Map<String, dynamic>>((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  /// Get nearby verified rooms within specified radius
  Future<List<Map<String, dynamic>>> _getNearbyVerifiedRooms(Position position, double radiusInMiles) async {
    try {
      final roomsSnapshot = await _verifiedRoomsCollection
          .where('isActive', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> nearbyRooms = [];

      for (final doc in roomsSnapshot.docs) {
        final roomData = doc.data() as Map<String, dynamic>;
        final roomLocation = roomData['location'] as GeoPoint;

        final distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          roomLocation.latitude,
          roomLocation.longitude,
        );

        final distanceInMiles = distanceInMeters * 0.000621371;
        if (distanceInMiles <= radiusInMiles) {
          nearbyRooms.add({
            'id': doc.id,
            ...roomData,
            'distance': distanceInMiles,
          });
        }
      }

      return nearbyRooms;
    } catch (e) {
      print('Error getting nearby verified rooms: $e');
      return [];
    }
  }

  /// Get fallback major cities when location is not available
  Stream<List<Map<String, dynamic>>> getFallbackCities() {
    return _citiesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .limit(10) // Limit to top 10 cities
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

  /// Join nearby users queue
  Future<void> joinNearbyQueue(String locationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      
      // Get the correct user display name from Firestore profile
      final userName = await _getUserDisplayName();
      print('Joining nearby queue for location $locationId, user: $uid, name: $userName');

      await _firestore.collection('nearby_queue_$locationId').doc(uid).set({
        'userId': uid,
        'name': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Joined nearby queue for location $locationId, user: $uid');
    } catch (e) {
      print('Error joining nearby queue: $e');
    }
  }
} 