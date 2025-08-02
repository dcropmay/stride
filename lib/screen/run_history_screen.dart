import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/run_record.dart';

class RunHistoryScreen extends StatefulWidget {
  const RunHistoryScreen({super.key});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  List<RunRecord> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    try {
      final runs = await FirestoreService().getUserRuns();
      setState(() {
        _runs = runs;
        _loading = false;
      });
    } catch (e) {
      print('Error loading run history: $e');
    }
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy – h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run History'),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _runs.isEmpty
              ? const Center(child: Text('No run data available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _runs.length,
                  itemBuilder: (context, index) {
                    final run = _runs[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.directions_run, color: Colors.teal, size: 30),
                        title: Text(
                          '${run.distanceKm.toStringAsFixed(2)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Duration: ${run.duration}', style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 2),
                            Text('Date: ${formatDateTime(run.timestamp)}', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
