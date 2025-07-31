import 'package:flutter/material.dart';
import './super_simple_widget.dart';

class LiveQueuePage extends StatefulWidget {
  final VoidCallback? onNavigateToSpotlight;
  
  const LiveQueuePage({super.key, this.onNavigateToSpotlight});

  @override
  State<LiveQueuePage> createState() => _LiveQueuePageState();
}

class _LiveQueuePageState extends State<LiveQueuePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: const Text(
          'Spotlight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SuperSimpleWidget(
        onNavigateToSpotlight: widget.onNavigateToSpotlight,
      ),
    );
  }
}


