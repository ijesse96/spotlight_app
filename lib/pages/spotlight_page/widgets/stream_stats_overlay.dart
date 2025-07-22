import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StreamStatsOverlay extends StatelessWidget {
  final String viewerCount;
  final int coinCount;
  final Stream<Map<String, dynamic>?>? timerStream;
  final Stream<Map<String, dynamic>?>? liveUserStream;

  const StreamStatsOverlay({
    super.key,
    this.viewerCount = "1.2K",
    this.coinCount = 0,
    this.timerStream,
    this.liveUserStream,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye, color: Color(0xFFFFB74D), size: 16),
            const SizedBox(width: 4),
            Text(
              viewerCount,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (timerStream != null)
          StreamBuilder<Map<String, dynamic>?>(
            stream: timerStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                  ),
                );
              }
              
              final data = snapshot.data!;
              final countdown = data['countdown'] ?? 20;
              final isActive = data['isActive'] ?? false;
              
              // Check if there's a live user to determine if timer should be active
              if (liveUserStream != null) {
                return StreamBuilder<Map<String, dynamic>?>(
                  stream: liveUserStream,
                  builder: (context, liveUserSnapshot) {
                    final hasLiveUser = liveUserSnapshot.hasData && liveUserSnapshot.data != null;
                    // If there's a live user, show timer as active (white) regardless of isActive flag
                    // Also show as active if timer is active (to prevent flickering during stream loading)
                    // If live user stream is still loading, assume active if timer is active
                    final shouldShowActive = hasLiveUser || isActive || (liveUserSnapshot.connectionState == ConnectionState.waiting && isActive);
                    
                    if (!shouldShowActive) return const SizedBox.shrink();
                    
                    return Text(
                      '$countdown s',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                );
              }
              
              // If no live user stream provided, just check isActive
              if (!isActive) return const SizedBox.shrink();
              
              return Text(
                '$countdown s',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.coins, color: Color(0xFFFFB74D), size: 16),
            const SizedBox(width: 4),
            Text(
              "$coinCount",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
} 