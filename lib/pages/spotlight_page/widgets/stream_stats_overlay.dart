import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/super_simple_queue.dart';

class StreamStatsOverlay extends StatelessWidget {
  final String viewerCount;
  final int coinCount;
  final Stream<int>? timerStream;
  final Stream<SuperSimpleUser?>? liveUserStream;

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
          StreamBuilder<int>(
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
              
              final countdown = snapshot.data!;
              
              // Check if there's a live user to determine if timer should be active
              if (liveUserStream != null) {
                return StreamBuilder<SuperSimpleUser?>(
                  stream: liveUserStream,
                  builder: (context, liveUserSnapshot) {
                    final hasLiveUser = liveUserSnapshot.hasData && liveUserSnapshot.data != null;
                    
                    if (!hasLiveUser || countdown <= 0) return const SizedBox.shrink();
                    
                    return Text(
                      '$countdown s',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                );
              }
              
              // If no live user stream provided, just check countdown
              if (countdown <= 0) return const SizedBox.shrink();
              
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