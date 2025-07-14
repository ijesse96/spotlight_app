import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  // Create a test VLR room
  await firestore.collection('verified_rooms').doc('test_vlr_room').set({
    'name': 'Test VLR Room',
    'description': 'A test VLR room for development and testing',
    'cityId': 'test_city',
    'location': GeoPoint(40.7128, -74.0060), // New York coordinates
    'maxDistanceMiles': 0.2,
    'createdAt': FieldValue.serverTimestamp(),
  });

  print('Test VLR room created successfully!');
  print('Room ID: test_vlr_room');
  print('Location: New York (40.7128, -74.0060)');
  print('Max Distance: 0.2 miles');
} 