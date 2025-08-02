import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../models/run_record.dart';
import 'package:audioplayers/audioplayers.dart';



class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen> {
  GoogleMapController? _mapController;
  final List<LatLng> _routeCoords = [];
  Set<Polyline> _polylines = {};
  Position? _lastPosition;

  bool _isTracking = false;
  double _totalDistance = 0.0;
  Duration _elapsed = Duration.zero;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _currentPace = "-";
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _lastSoundDistance = 0.0;



  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition();
    _routeCoords.clear();
    _routeCoords.add(LatLng(pos.latitude, pos.longitude));
    _lastPosition = pos;

    _stopwatch.start();
    _isTracking = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final currentPos = await Geolocator.getCurrentPosition();

      if (_lastPosition != null) {
        double d = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          currentPos.latitude,
          currentPos.longitude,
        );

        if (_totalDistance - _lastSoundDistance >= 1000) {
          _lastSoundDistance += 1000;
          _playSound();
        }


        if (d > 5) {
          _totalDistance += d;
          _routeCoords.add(LatLng(currentPos.latitude, currentPos.longitude));
          _lastPosition = currentPos;

          _updatePolyline();
          _mapController?.animateCamera(CameraUpdate.newLatLng(
              LatLng(currentPos.latitude, currentPos.longitude)));
        }
      }

     setState(() {
      _elapsed = _stopwatch.elapsed;

      if (_totalDistance >= 10) {
        final minutes = _elapsed.inSeconds / 60.0;
        final distanceInKm = _totalDistance / 1000;
        _currentPace = (minutes / distanceInKm).toStringAsFixed(1);
      } else {
      _currentPace = "-";
    }
});

    });

    setState(() {});
  }

void _stopTracking() async {
  _stopwatch.stop();
  _timer?.cancel();

  setState(() {
    _isTracking = false;
  });

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User not logged in.")),
    );
    return;
  }

  final runRecord = RunRecord(
    userId: user.uid,
    distanceKm: _totalDistance / 1000,
    duration: _formatDuration(_elapsed),
    pace: _currentPace,
    timestamp: DateTime.now(),
    route: _routeCoords,
  );

  await FirestoreService().saveRun(runRecord);
  _showSummaryDialog();
}

  Future<void> _playSound() async {
  try {
    await _audioPlayer.play(AssetSource('assets/sounds/ding.mp3'));
  } catch (e) {
    print("Error playing sound: $e");
  }
}


  void _updatePolyline() {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId("run_route"),
          points: _routeCoords,
          color: Colors.teal,
          width: 6,
        )
      };
    });
  }

  void _showSummaryDialog() {
    final km = (_totalDistance / 1000).toStringAsFixed(2);
    final minutes = _elapsed.inMinutes;
    final pace = _totalDistance > 0
        ? (minutes / (_totalDistance / 1000)).toStringAsFixed(1)
        : "-";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Run Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Distance: $km km'),
            Text('Time: ${_formatDuration(_elapsed)}'),
            Text('Pace: $pace min/km'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _reset() {
    _stopwatch.reset();
    _elapsed = Duration.zero;
    _totalDistance = 0.0;
    _routeCoords.clear();
    _polylines.clear();
    _lastPosition = null;
    _currentPace = "-";

    setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Stride')),
    body: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(20.5937, 78.9629), // India center
            zoom: 15,
          ),
          onMapCreated: (controller) => _mapController = controller,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Time: ${_formatDuration(_elapsed)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Pace: $_currentPace min/km',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
      


                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTracking ? 'Stop Run' : 'Start Run'),
                  onPressed: _isTracking ? _stopTracking : _startTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
