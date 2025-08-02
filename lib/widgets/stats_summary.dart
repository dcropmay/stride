import 'package:flutter/material.dart';

class StatsSummary extends StatelessWidget {
  final double weeklyGoal;
  final double currentProgress;
  final double totalDistance;
  final String totalTime;
  final String avgPace;

  const StatsSummary({
    super.key,
    required this.weeklyGoal,
    required this.currentProgress,
    required this.totalDistance,
    required this.totalTime,
    required this.avgPace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Weekly Goal
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🎯 Weekly Goal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Distance: ${weeklyGoal.toStringAsFixed(1)} km", style: const TextStyle(fontSize: 16)),
                Text("Progress: ${currentProgress.toStringAsFixed(1)} km", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Total Stats
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📊 Your Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Total Distance: ${totalDistance.toStringAsFixed(1)} km", style: const TextStyle(fontSize: 16)),
                Text("Total Time: $totalTime", style: const TextStyle(fontSize: 16)),
                Text("Avg Pace: $avgPace min/km", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
