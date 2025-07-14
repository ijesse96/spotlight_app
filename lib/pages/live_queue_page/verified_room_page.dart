import 'package:flutter/material.dart';

class VerifiedRoomPage extends StatelessWidget {
  final String roomId;
  final String roomName;
  final String description;

  const VerifiedRoomPage({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        backgroundColor: const Color(0xFFFFB74D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              size: 64,
              color: Color(0xFFFFB74D),
            ),
            const SizedBox(height: 16),
            Text(
              roomName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verified Location Room',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFFB74D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This room requires physical proximity to join',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 