import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/run_record.dart';
import '../services/firestore_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<RunRecord> runs = [];
  double totalDistance = 0.0;
  double averagePace = 0.0;
  double weeklyGoal = 15.0;
  double currentWeekDistance = 0.0;
  Map<String, double> weeklyDistances = {};
  List<FlSpot> distanceOverTime = [];
  List<FlSpot> paceOverTime = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
  final fetchedRuns = await FirestoreService().getUserRuns();
  final fetchedGoal = await FirestoreService().getWeeklyGoal();

  double distanceSum = 0;
  double paceSum = 0;
  int validPaceCount = 0;
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  Map<String, double> tempWeekly = {};

  List<FlSpot> distanceSpots = [];
  List<FlSpot> paceSpots = [];

  double tempWeekDistance = 0;

  for (int i = 0; i < fetchedRuns.length; i++) {
    final run = fetchedRuns[i];
    distanceSum += run.distanceKm;

    final pace = double.tryParse(run.pace);
    if (pace != null) {
      paceSum += pace;
      validPaceCount++;
      paceSpots.add(FlSpot(i.toDouble(), pace));
    }

    distanceSpots.add(FlSpot(i.toDouble(), run.distanceKm));

    final runDate = run.timestamp;
    final dateKey = DateFormat('EEE').format(runDate);
    tempWeekly[dateKey] = (tempWeekly[dateKey] ?? 0) + run.distanceKm;

    if (runDate.isAfter(weekStart)) {
      tempWeekDistance += run.distanceKm;
    }
  }

  setState(() {
    runs = fetchedRuns;
    totalDistance = distanceSum;
    averagePace = validPaceCount > 0 ? paceSum / validPaceCount : 0.0;
    weeklyDistances = tempWeekly;
    distanceOverTime = distanceSpots;
    paceOverTime = paceSpots;
    currentWeekDistance = tempWeekDistance;
    weeklyGoal = fetchedGoal;
  });
}

  @override
  Widget build(BuildContext context) {
    final double progress = (weeklyGoal > 0)
        ? (currentWeekDistance / weeklyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Weekly Distance"),
              _buildWeeklyBarChart(),
              const SizedBox(height: 30),
              _buildSectionTitle("Distance Over Runs"),
              _buildLineChart(distanceOverTime),
              const SizedBox(height: 30),
              _buildSectionTitle("Pace Over Runs"),
              _buildLineChart(paceOverTime),
              const SizedBox(height: 30),
              _buildSummaryCard("Total Distance", "${totalDistance.toStringAsFixed(1)} km"),
              _buildSummaryCard("Average Pace", "${averagePace.toStringAsFixed(2)} min/km"),
              _buildSummaryCard("Weekly Goal", "${currentWeekDistance.toStringAsFixed(2)} / ${weeklyGoal.toStringAsFixed(2)} km"),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWeeklyBarChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final weekday = DateFormat.E().format(DateTime.now().subtract(Duration(days: 6 - value.toInt())));
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(weekday, style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(7, (index) {
            final day = DateFormat.E().format(DateTime.now().subtract(Duration(days: 6 - index)));
            final y = weeklyDistances[day] ?? 0;
            return BarChartGroupData(x: index, barRods: [
              BarChartRodData(toY: y, color: Colors.teal, width: 16),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> data) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: Colors.teal,
              barWidth: 2,
            )
          ],
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.show_chart, color: Colors.teal),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
