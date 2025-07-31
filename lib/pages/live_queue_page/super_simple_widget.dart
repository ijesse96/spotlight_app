import 'package:flutter/material.dart';
import '../../services/super_simple_queue.dart';

class SuperSimpleWidget extends StatefulWidget {
  final VoidCallback? onNavigateToSpotlight;
  
  const SuperSimpleWidget({super.key, this.onNavigateToSpotlight});

  @override
  State<SuperSimpleWidget> createState() => _SuperSimpleWidgetState();
}

class _SuperSimpleWidgetState extends State<SuperSimpleWidget> {
  final SuperSimpleQueue _queue = SuperSimpleQueue();

  Future<void> _joinQueue() async {
    try {
      await _queue.joinQueue();
      print("✅ Joined queue successfully!");
    } catch (e) {
      print("❌ Error joining queue: $e");
    }
  }

  Future<void> _leaveQueue() async {
    try {
      await _queue.leaveQueue();
      print("✅ Left queue successfully!");
    } catch (e) {
      print("❌ Error leaving queue: $e");
    }
  }

  Future<void> _goLive() async {
    try {
      await _queue.goLive();
      print("✅ Went live successfully!");
    } catch (e) {
      print("❌ Error going live: $e");
    }
  }

  Future<void> _rotate() async {
    try {
      await _queue.rotateToNext();
      print("✅ Rotated to next user successfully!");
    } catch (e) {
      print("❌ Error rotating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Live user card - tappable to navigate to Spotlight
        StreamBuilder<List<SuperSimpleUser>>(
          stream: _queue.queueStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SizedBox.shrink();
            }

            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final users = snapshot.data!;
            final liveUser = users.where((user) => user.isLive).firstOrNull;
            
            // Only show the card if someone is live
            if (liveUser == null) {
              return const SizedBox.shrink(); // Hide the card completely
            }
            
            return GestureDetector(
              onTap: () {
                if (widget.onNavigateToSpotlight != null) {
                  widget.onNavigateToSpotlight!();
                }
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.live_tv, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live: ${liveUser.name}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Tap to watch stream',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timer
                    StreamBuilder<int>(
                      stream: _queue.timerStream,
                      builder: (context, timerSnapshot) {
                        final seconds = timerSnapshot.data ?? 0;
                        if (seconds <= 0) {
                          return const Text('--');
                        }
                        return Text(
                          '${seconds}s',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        );
                      },
                    ),
                    // Arrow indicator
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Add top padding when no live user card is shown
        StreamBuilder<List<SuperSimpleUser>>(
          stream: _queue.queueStream,
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox(height: 32); // Default padding
            }

            final users = snapshot.data!;
            final liveUser = users.where((user) => user.isLive).firstOrNull;
            
            // Add padding when no live user card is shown
            if (liveUser == null) {
              return const SizedBox(height: 32); // Top padding when no live card
            }
            
            return const SizedBox.shrink(); // No extra padding when live card is shown
          },
        ),
        
        // Control buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
                                        // Join/Leave button
                          StreamBuilder<bool>(
                            stream: _queue.userInQueueStream,
                            builder: (context, snapshot) {
                              final isInQueue = snapshot.data ?? false;
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isInQueue ? _leaveQueue : _joinQueue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isInQueue ? Colors.grey : Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(isInQueue ? 'Leave Queue' : 'Join Queue'),
                                ),
                              );
                            },
                          ),
              
              const SizedBox(height: 8),
              
                                        // Go Live button
                          StreamBuilder<bool>(
                            stream: _queue.userInQueueStream,
                            builder: (context, snapshot) {
                              final isInQueue = snapshot.data ?? false;
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isInQueue ? _goLive : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Go Live'),
                                ),
                              );
                            },
                          ),
              
              const SizedBox(height: 8),
              
              // Manual rotate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rotate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Manual Rotate'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // Queue list
        Expanded(
          child: StreamBuilder<List<SuperSimpleUser>>(
            stream: _queue.queueStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!;
              
              if (users.isEmpty) {
                return const Center(
                  child: Text('Queue is empty'),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Text('Joined ${_formatTime(user.joinedAt)}'),
                    trailing: user.isLive 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
} 