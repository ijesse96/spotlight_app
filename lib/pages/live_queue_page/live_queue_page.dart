import 'package:flutter/material.dart';
import './local_queue_detail_page.dart';
import './local_spotlight_page.dart';
import './spotlight_queue_widget.dart';
import './local_tab_widget.dart';

class LiveQueuePage extends StatefulWidget {
  final int initialTabIndex;
  
  const LiveQueuePage({super.key, this.initialTabIndex = 0});

  @override
  State<LiveQueuePage> createState() => _LiveQueuePageState();
}

class _LiveQueuePageState extends State<LiveQueuePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Key _spotlightKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to tab changes and force a new key for Spotlight tab
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        setState(() {
          _spotlightKey = UniqueKey();
        });
      }
    });
    
    // Set the initial tab based on the parameter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex == 1) {
        _tabController.animateTo(1);
        setState(() {
          _spotlightKey = UniqueKey();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildQueueCard(String title, int usersInQueue) {
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.group, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(usersInQueue.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(orangeColor),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocalQueueDetailPage(title: title),
                      ),
                    );
                  },
                  child: const Text('Join Queue'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return orangeColor.withOpacity(0.15);
                      }
                      return Colors.white;
                    }),
                    foregroundColor: MaterialStateProperty.all(orangeColor),
                    side: MaterialStateProperty.all(BorderSide(color: orangeColor)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocalSpotlightPage(
                          locationId: 'test-location',
                          liveUserName: "Emma",
                          viewerCount: 1200,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Stream'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        elevation: 0,
        centerTitle: true,
        title: const Text('Live Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Local'),
            Tab(text: 'Spotlight'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Local tab
          const LocalTabWidget(),

          // Spotlight tab
          SpotlightQueueWidget(key: _spotlightKey),
        ],
      ),
    );
  }
}


