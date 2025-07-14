import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import './verified_room_page.dart';
import './city_stream_page.dart';
import './vlr_stream_page.dart';
import './city_queue_list_page.dart';
import './vlr_queue_list_page.dart';

class CityPage extends StatefulWidget {
  final String cityId;
  final String cityName;
  final String state;

  const CityPage({
    Key? key,
    required this.cityId,
    required this.cityName,
    required this.state,
  }) : super(key: key);

  @override
  _CityPageState createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  final LocationService _locationService = LocationService();

  // Mock verified rooms for each city
  Map<String, List<Map<String, dynamic>>> _getVerifiedRoomsForCity(String cityId) {
    switch (cityId) {
      case 'los_angeles':
        return {
          'verified_rooms': [
            {
              'id': 'usc_campus',
              'name': 'USC Campus',
              'description': 'University of Southern California',
              'location': {'latitude': 34.0224, 'longitude': -118.2851},
              'maxDistance': 0.2,
            },
            {
              'id': 'sofi_stadium',
              'name': 'SoFi Stadium',
              'description': 'Home of the LA Rams and Chargers',
              'location': {'latitude': 33.9533, 'longitude': -118.3387},
              'maxDistance': 0.2,
            },
            {
              'id': 'ucla_campus',
              'name': 'UCLA Campus',
              'description': 'University of California, Los Angeles',
              'location': {'latitude': 34.0689, 'longitude': -118.4452},
              'maxDistance': 0.2,
            },
          ]
        };
      case 'new_york':
        return {
          'verified_rooms': [
            {
              'id': 'times_square',
              'name': 'Times Square',
              'description': 'The Crossroads of the World',
              'location': {'latitude': 40.7580, 'longitude': -73.9855},
              'maxDistance': 0.2,
            },
            {
              'id': 'central_park',
              'name': 'Central Park',
              'description': 'Urban oasis in Manhattan',
              'location': {'latitude': 40.7829, 'longitude': -73.9654},
              'maxDistance': 0.2,
            },
          ]
        };
      default:
        return {'verified_rooms': []};
    }
  }

  Widget _buildCityHeader() {
    const Color orangeColor = Color(0xFFFFB74D);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [orangeColor, orangeColor.withOpacity(0.8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cityName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.state,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _locationService.getCityQueueUsers(widget.cityId),
                builder: (context, snapshot) {
                  final userCount = snapshot.data?.length ?? 0;
                  return Text(
                    '$userCount people in city lobby',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCityQueueSection() {
    const Color orangeColor = Color(0xFFFFB74D);

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, color: orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'City-Wide Lobby',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Anyone can join from anywhere - no location restrictions',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<Map<String, dynamic>?>(
                    stream: _locationService.getCurrentUserCityQueueStatus(widget.cityId),
                    builder: (context, snapshot) {
                      final isInQueue = snapshot.data != null;
                      
                      return ElevatedButton(
                        onPressed: () {
                          if (isInQueue) {
                            _showLeaveQueueDialog();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CityQueueListPage(
                                  cityId: widget.cityId,
                                  cityName: widget.cityName,
                                  state: widget.state,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInQueue ? Colors.grey[400] : orangeColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isInQueue ? 'Leave City Queue' : 'Join City Queue',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CityStreamPage(
                          cityId: widget.cityId,
                          cityName: widget.cityName,
                          state: widget.state,
                        ),
                      ),
                    );
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

  Widget _buildVerifiedRoomCard(Map<String, dynamic> room) {
    const Color orangeColor = Color(0xFFFFB74D);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: orangeColor.withOpacity(0.1),
                  child: Icon(Icons.verified, color: orangeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        room['description'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
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
                Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Within ${room['maxDistance']} miles to join',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _locationService.getVerifiedRoomQueueUsers(room['id']),
                  builder: (context, snapshot) {
                    final userCount = snapshot.data?.length ?? 0;
                    return Text(
                      '$userCount in queue',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<Map<String, dynamic>?>(
              stream: _locationService.getCurrentUserVerifiedRoomQueueStatus(room['id']),
              builder: (context, snapshot) {
                final isInQueue = snapshot.data != null;
                
                if (isInQueue) {
                  // User is in queue, show leave button
                  return ElevatedButton(
                    onPressed: () async {
                      await _locationService.leaveVerifiedRoomQueue(room['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Leave Room Queue'),
                  );
                } else {
                  // User is not in queue, show join buttons
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final success = await _locationService.joinVerifiedRoomQueue(room['id']);
                          if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You must be within 0.2 miles to join this room'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Join ${room['name']} Queue'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final success = await _locationService.joinVerifiedRoomQueueForTesting(room['id']);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Successfully joined VLR queue for testing!'),
                                backgroundColor: Color(0xFFFFB74D),
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to join VLR queue'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                        child: const Text('Join Queue (Test Mode - No Location Check)'),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VLRStreamPage(
                            roomId: room['id'],
                            roomName: room['name'],
                            description: room['description'],
                            location: room['location'],
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orangeColor,
                      side: BorderSide(color: orangeColor),
                    ),
                    child: const Text('View Stream'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VLRQueueListPage(
                            roomId: room['id'],
                            roomName: room['name'],
                            description: room['description'],
                            location: room['location'],
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orangeColor,
                      side: BorderSide(color: orangeColor),
                    ),
                    child: const Text('View Queue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveQueueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave City Queue?'),
        content: const Text('Are you sure you want to leave the city queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _locationService.leaveCityQueue(widget.cityId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB74D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave Queue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifiedRooms = _getVerifiedRoomsForCity(widget.cityId)['verified_rooms'] as List<Map<String, dynamic>>;

    return Scaffold(
      body: Column(
        children: [
          _buildCityHeader(),
          Expanded(
            child: ListView(
              children: [
                _buildCityQueueSection(),
                if (verifiedRooms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFFFFB74D)),
                        const SizedBox(width: 8),
                        const Text(
                          'Verified Location Rooms',
                          style: TextStyle(
                            fontSize: 18,
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
                      'Join these rooms only if you\'re physically nearby',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...verifiedRooms.map((room) => _buildVerifiedRoomCard(room)).toList(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 