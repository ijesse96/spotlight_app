import 'dart:async';
import 'package:flutter/material.dart';

class LocalQueueDetailPage extends StatefulWidget {
  final String title;

  const LocalQueueDetailPage({Key? key, required this.title}) : super(key: key);

  @override
  _LocalQueueDetailPageState createState() => _LocalQueueDetailPageState();
}

class _LocalQueueDetailPageState extends State<LocalQueueDetailPage> {
  bool hasJoined = false;
  bool isReady = false;
  Duration countdown = const Duration(seconds: 15);
  Timer? _timer;

  Map<String, dynamic>? currentLiveUser;

  final List<Map<String, dynamic>> queueUsers = [
    {"name": "Alex", "ready": true},
    {"name": "Bri", "ready": false},
    {"name": "Jordan", "ready": true},
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.inSeconds == 0) {
        _moveToNextStreamer();
      } else {
        setState(() {
          countdown = Duration(seconds: countdown.inSeconds - 1);
        });
      }
    });
  }

  void _moveToNextStreamer() {
    setState(() {
      if (queueUsers.isNotEmpty) {
        currentLiveUser = queueUsers.removeAt(0);
        countdown = const Duration(seconds: 15);
      } else {
        currentLiveUser = null;
        countdown = const Duration(seconds: 15);
      }
    });
  }

  void _confirmJoin() {
    if (!hasJoined) {
      setState(() {
        hasJoined = true;
        isReady = false;
        queueUsers.add({"name": "You", "ready": isReady});
      });
    } else {
      setState(() {
        isReady = !isReady;
        final index = queueUsers.indexWhere((user) => user["name"] == "You");
        if (index != -1) {
          queueUsers[index]["ready"] = isReady;
        }
      });
    }
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    const Color orangeColor = Color(0xFFFFB74D);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(user["name"], style: const TextStyle(fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user["ready"] ? orangeColor : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user["ready"] ? "Ready" : "Not Ready",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStreamerCard() {
    const Color orangeColor = Color(0xFFFFB74D);

    if (currentLiveUser == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: const [
            CircleAvatar(child: Icon(Icons.live_tv, color: Colors.black)),
            SizedBox(width: 12),
            Expanded(
              child: Text("Waiting for next streamer...",
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: orangeColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.live_tv, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  "Live Now: ${currentLiveUser!['name']}",
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
            ),
          ),
          Text(
            "${countdown.inSeconds}s",
            style: TextStyle(
              color: orangeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFFFB74D);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: orangeColor,
      ),
      body: Column(
        children: [
          _buildCurrentStreamerCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasJoined
                      ? (isReady ? Colors.grey.shade400 : orangeColor)
                      : orangeColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  hasJoined
                      ? (isReady ? "Unready" : "Ready")
                      : "Confirm Join",
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: queueUsers.length,
              itemBuilder: (context, index) {
                final user = queueUsers[index];
                return _buildUserRow(user);
              },
            ),
          ),
        ],
      ),
    );
  }
}
