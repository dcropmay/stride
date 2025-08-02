import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunRecord {
  final String userId;
  final double distanceKm;
  final String duration;
  final String pace;
  final DateTime timestamp;
  final List<LatLng> route;

  RunRecord({
    required this.userId,
    required this.distanceKm,
    required this.duration,
    required this.pace,
    required this.timestamp,
    required this.route,
  });

  factory RunRecord.fromMap(Map<String, dynamic> data) {
    return RunRecord(
      userId: data['userId'] ?? '', 
      distanceKm: (data['distanceKm'] as num).toDouble(),
      duration: data['duration'],
      pace: data['pace'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      route: (data['route'] as List<dynamic>)
          .map((pt) => LatLng(pt['lat'], pt['lng']))
          .toList(),
    );
  }
}
