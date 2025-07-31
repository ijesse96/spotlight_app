import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/location_service.dart';
import './city_page.dart';
import './verified_room_page.dart';
import './local_queue_detail_page.dart';
import './nearby_stream_page.dart';
import './vlr_stream_page.dart';
import './city_queue_list_page.dart';
import './vlr_queue_list_page.dart';
import './nearby_queue_list_page.dart';
import '../../services/queue/index.dart';

class LocalTabWidget extends StatefulWidget {
  const LocalTabWidget({Key? key}) : super(key: key);

  @override
  _LocalTabWidgetState createState() => _LocalTabWidgetState();
}

class _LocalTabWidgetState extends State<LocalTabWidget> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _hasLocationPermission = false;
  bool _isPermissionDeniedForever = false;
  List<Map<String, dynamic>> _nearbyQueues = [];
  List<Map<String, dynamic>> _fallbackCities = [];
  StreamSubscription? _nearbyQueuesSubscription;
  StreamSubscription? _fallbackCitiesSubscription;

  // Major US cities for exploration
  final List<Map<String, dynamic>> _majorCities = [
    {'id': 'los_angeles', 'name': 'Los Angeles', 'state': 'CA'},
    {'id': 'new_york', 'name': 'New York City', 'state': 'NY'},
    {'id': 'atlanta', 'name': 'Atlanta', 'state': 'GA'},
    {'id': 'chicago', 'name': 'Chicago', 'state': 'IL'},
    {'id': 'miami', 'name': 'Miami', 'state': 'FL'},
    {'id': 'dallas', 'name': 'Dallas', 'state': 'TX'},
    {'id': 'phoenix', 'name': 'Phoenix', 'state': 'AZ'},
    {'id': 'denver', 'name': 'Denver', 'state': 'CO'},
    {'id': 'seattle', 'name': 'Seattle', 'state': 'WA'},
    {'id': 'boston', 'name': 'Boston', 'state': 'MA'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    
    // Listen for app lifecycle changes to check permission when app resumes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nearbyQueuesSubscription?.cancel();
    _fallbackCitiesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check location permission when app resumes
      _initializeLocation();
      // Also check if user returned from settings
      _handleSettingsReturn();
    }
  }

  /// Handle when user returns from settings
  Future<void> _handleSettingsReturn() async {
    final hasPermission = await _locationService.hasLocationPermission();
    if (hasPermission && !_hasLocationPermission) {
      // Permission was granted while in settings
      setState(() {
        _hasLocationPermission = true;
        _isPermissionDeniedForever = false;
      });
      await _initializeLocation();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location access enabled! You can now see nearby users.'),
            backgroundColor: Color(0xFFFFB74D),
          ),
        );
      }
    }
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.hasLocationPermission();
    final isDeniedForever = await _locationService.isLocationPermissionDeniedForever();
    
    if (mounted) {
    setState(() {
      _hasLocationPermission = hasPermission;
      _isPermissionDeniedForever = isDeniedForever;
    });
    }

    if (hasPermission) {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        // Update user's location in Firestore
        await _locationService.updateUserLocation(position);
        
        // Start listening for nearby queues
        _startNearbyQueuesListener();
      }
    } else {
      // Start fallback cities listener when location is not available
      _startFallbackCitiesListener();
    }
  }

  /// Start listening for nearby queues
  void _startNearbyQueuesListener() {
    _nearbyQueuesSubscription?.cancel();
    _nearbyQueuesSubscription = _locationService.discoverNearbyQueues().listen(
      (queues) {
        if (mounted) {
          setState(() {
            _nearbyQueues = queues;
          });
        }
      },
      onError: (error) {
        print('Error listening to nearby queues: $error');
      },
    );
  }

  /// Start listening for fallback cities
  void _startFallbackCitiesListener() {
    _fallbackCitiesSubscription?.cancel();
    _fallbackCitiesSubscription = _locationService.getFallbackCities().listen(
      (cities) {
        if (mounted) {
          setState(() {
            _fallbackCities = cities;
          });
        }
      },
      onError: (error) {
        print('Error listening to fallback cities: $error');
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    final granted = await _locationService.requestLocationPermission();
    
    if (granted) {
      await _initializeLocation();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location access granted! Finding nearby users...'),
            backgroundColor: Color(0xFFFFB74D),
          ),
        );
      }
    } else {
      // Check if permission was denied forever
      final isDeniedForever = await _locationService.isLocationPermissionDeniedForever();
      setState(() {
        _isPermissionDeniedForever = isDeniedForever;
      });
      
      // Show dialog explaining why location is needed
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(isDeniedForever ? 'Location Access Blocked' : 'Location Access Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeniedForever 
                      ? 'Location access has been permanently denied.'
                      : 'Spotlight needs location access to:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!isDeniedForever) ...[
                  const SizedBox(height: 8),
                  const Text('• Show nearby users in your area'),
                  const Text('• Join verified location rooms'),
                  const Text('• Provide location-based streaming'),
                ],
                const SizedBox(height: 8),
                const Text(
                  'You can still explore city-wide lobbies without location access.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                if (isDeniedForever) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'To enable location access, go to your device settings and allow location access for Spotlight.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
              if (isDeniedForever)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _locationService.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Open Settings'),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Try requesting permission again, but don't show dialog again if denied
                    final retryGranted = await _locationService.requestLocationPermission();
                    if (retryGranted) {
                      await _initializeLocation();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location access granted! Finding nearby users...'),
                            backgroundColor: Color(0xFFFFB74D),
                          ),
                        );
                      }
                    } else {
                      // Permission still denied, update state but don't show dialog again
                      final isStillDeniedForever = await _locationService.isLocationPermissionDeniedForever();
                      setState(() {
                        _isPermissionDeniedForever = isStillDeniedForever;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location access denied. You can still explore city-wide lobbies.'),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable Location'),
                ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildNearbyQueuesSection() {
    const Color orangeColor = Color(0xFFFFB74D);

    if (_nearbyQueues.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'No Nearby Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'No users or verified rooms found nearby. Check back later or explore city-wide lobbies.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _nearbyQueues.map((queue) => _buildQueueCard(queue)).toList(),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> queue) {
    const Color orangeColor = Color(0xFFFFB74D);
    final String type = queue['type'] ?? 'unknown';
    final String label = queue['label'] ?? 'Unknown Queue';
    final int count = queue['count'] ?? 0;
    final String distance = queue['distance'] ?? 'unknown';

    IconData icon;
    String subtitle;

    if (type == 'nearby_users') {
      icon = Icons.people;
      subtitle = 'Queue within $distance';
    } else if (type == 'verified_room') {
      icon = Icons.location_on;
      subtitle = 'Verified location room - $distance';
    } else {
      icon = Icons.queue;
      subtitle = 'Queue activity';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: orangeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (type == 'nearby_users') {
                        // Use new modular backend for joining local queue
                        final locationId = queue['locationId'] ?? 'nearby_unknown';
                        final localQueueController = UnifiedQueueService().getLocalQueue(locationId);
                        try {
                          await localQueueController.joinQueue();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joined local queue: $label'),
                                backgroundColor: orangeColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to join queue: $e'),
                                backgroundColor: Colors.red,
                          ),
                        );
                          }
                        }
                      } else if (type == 'verified_room') {
                        // Use new modular backend for joining VLR queue
                        final roomId = queue['roomId'] ?? 'unknown_room';
                        final roomName = queue['roomName'] ?? label;
                        final vlrQueueController = UnifiedQueueService().getVLRQueue(roomId);
                        try {
                          await vlrQueueController.joinQueue();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joined verified room: $roomName'),
                                backgroundColor: orangeColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to join verified room: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else if (type == 'city_lobby') {
                        // Use new modular backend for joining city queue
                        final cityId = queue['cityId'] ?? queue['id'] ?? 'unknown_city';
                        final cityName = queue['cityName'] ?? queue['name'] ?? label;
                        final cityQueueController = UnifiedQueueService().getCityQueue(cityId);
                        try {
                          await cityQueueController.joinQueue();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joined city lobby: $cityName'),
                                backgroundColor: orangeColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to join city lobby: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        // Fallback: show not supported
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Queue type not supported for migration: $type'),
                              backgroundColor: Colors.red,
                          ),
                        );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Join Queue'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    if (type == 'nearby_users') {
                      // Navigate to nearby stream
                      // Generate locationId for nearby users (using current location as identifier)
                      final locationId = queue['locationId'] ?? 'nearby_unknown';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NearbyStreamPage(
                            locationId: locationId,
                            locationName: label ?? 'Nearby Users',
                            distance: double.tryParse((distance ?? '5').replaceAll(' miles', '')) ?? 5.0,
                          ),
                        ),
                      );
                    } else if (type == 'verified_room') {
                      // Navigate to VLR stream
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VLRStreamPage(
                            roomId: queue['roomId'],
                            roomName: queue['roomName'],
                            description: 'Verified location room within $distance',
                            location: queue['location'] ?? {'latitude': 0.0, 'longitude': 0.0},
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: orangeColor,
                    side: BorderSide(color: orangeColor),
                  ),
                  child: const Text('View Stream'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPermissionCard() {
    const Color orangeColor = Color(0xFFFFB74D);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPermissionDeniedForever 
                      ? Icons.location_disabled 
                      : Icons.location_off, 
                  color: Colors.grey.shade600
                ),
                const SizedBox(width: 8),
                Text(
                  _isPermissionDeniedForever 
                      ? 'Location Access Blocked'
                      : 'Location Access Required',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isPermissionDeniedForever
                  ? 'Location access is permanently denied. You can still explore city-wide lobbies.'
                  : 'Enable location to see nearby users and join verified location rooms.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_isPermissionDeniedForever) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _locationService.openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Enable Location Access'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To enable location access:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('1. Open your device settings'),
                              Text('2. Find "Spotlight" in the app list'),
                              Text('3. Tap "Location"'),
                              Text('4. Select "While Using App" or "Always"'),
                              SizedBox(height: 8),
                              Text(
                                'This will allow you to see nearby users and join verified location rooms.',
                                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('How to Enable'),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _requestLocationPermission();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Enable Location'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Why Location Access?'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spotlight uses your location to:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('• Find users within 5-10 miles of you'),
                              Text('• Join verified location rooms (0.2 mile radius)'),
                              Text('• Provide hyper-local streaming experiences'),
                              const SizedBox(height: 8),
                              const Text(
                                'Your location is only used to find nearby users and is not shared with others.',
                                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Learn More'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCityCard(Map<String, dynamic> city) {
    const Color orangeColor = Color(0xFFFFB74D);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: orangeColor.withOpacity(0.1),
          child: Icon(Icons.location_city, color: orangeColor),
        ),
        title: Text(
          city['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${city['state']} • City-wide lobby'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CityPage(
                cityId: city['id'],
                cityName: city['name'],
                state: city['state'],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _initializeLocation,
      child: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Nearby Queues Section
          if (_hasLocationPermission) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFFB74D)),
                  const SizedBox(width: 8),
                  const Text(
                    'Nearby Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Real-time queues based on your location',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildNearbyQueuesSection(),
            const SizedBox(height: 24),
          ] else ...[
            _buildLocationPermissionCard(),
            const SizedBox(height: 24),
          ],
          
          // Explore Cities Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.explore, color: Color(0xFFFFB74D)),
                const SizedBox(width: 8),
                const Text(
                  'Explore Cities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Join city-wide lobbies from anywhere',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // City List (use fallback cities if location not available)
          ...(_hasLocationPermission ? _majorCities : _fallbackCities.isNotEmpty ? _fallbackCities : _majorCities)
              .map((city) => _buildCityCard(city))
              .toList(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
} 