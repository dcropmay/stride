import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/run_record.dart';
import 'package:stride/providers/theme_provider.dart';

class Badge {
  final String title;
  final String description;
  final IconData icon;
  final bool achieved;

  Badge(this.title, this.description, this.icon, this.achieved);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  double totalDistance = 0.0;
  int totalRuns = 0;
  double bestPace = 0.0;
  double _weeklyGoal = 15.0;
  int streak = 0;
  List<Badge> badges = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
  try {
    final runs = await FirestoreService().getUserRuns();
    final goal = await FirestoreService().getWeeklyGoal();
    double distance = 0.0;
    double? best;
    List<DateTime> runDates = [];

    for (final run in runs) {
      distance += run.distanceKm;
      double? paceValue = double.tryParse(run.pace);
      if (paceValue != null && (best == null || paceValue < best)) {
        best = paceValue;
      }
      runDates.add(run.timestamp);
    }

    setState(() {
      totalRuns = runs.length;
      totalDistance = distance;
      bestPace = best ?? 0.0;
      streak = _calculateStreak(runDates);
      badges = _generateBadges(runs, distance, bestPace);
      _weeklyGoal = goal;
    });
  } catch (e) {
    print("Error loading stats: $e");
  }
}

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    dates.sort((a, b) => b.compareTo(a));
    int streak = 1;
    DateTime current = dates.first;

    for (int i = 1; i < dates.length; i++) {
      final diff = current.difference(dates[i]).inDays;
      if (diff == 1) {
        streak++;
        current = dates[i];
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  List<Badge> _generateBadges(List<RunRecord> runs, double distance, double bestPace) {
    return [
      Badge("First Run", "Completed your first run", Icons.flag, runs.isNotEmpty),
      Badge("5 Runs", "Completed 5 runs", Icons.directions_run, runs.length >= 5),
      Badge("10 KM", "Ran 10 km in total", Icons.directions_walk, distance >= 10),
      Badge("Fast Runner", "Pace under 6:00", Icons.speed, bestPace < 6.0),
    ];
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Runner';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal.shade200,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            _buildStatCard("Total Distance", "${totalDistance.toStringAsFixed(1)} km"),
            _buildStatCard("Total Runs", "$totalRuns"),
            _buildStatCard("Best Pace", "${bestPace.toStringAsFixed(2)} min/km"),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.teal),
              title: const Text('Weekly Goal'),
              subtitle: Text('${_weeklyGoal.toStringAsFixed(1)} km'),
              trailing: const Icon(Icons.edit),
              onTap: () => _editWeeklyGoal(context),
          ),

            _buildStatCard("🔥 Streak", "$streak days"),

            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("🏅 Badges", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            _buildBadgeGrid(),

            const SizedBox(height: 30),
            SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.dark_mode, color: Colors.teal),
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (val) => context.read<ThemeProvider>().toggleTheme(val),
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _editWeeklyGoal(BuildContext context) {
  final controller = TextEditingController(text: _weeklyGoal.toString());
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit Weekly Goal'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Distance in km'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final newGoal = double.tryParse(controller.text);
            if (newGoal != null) {
              await FirestoreService().setWeeklyGoal(newGoal);
              setState(() => _weeklyGoal = newGoal);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

  Widget _buildBadgeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: badges.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final badge = badges[index];
        return Card(
          elevation: 3,
          color: badge.achieved ? Colors.teal.shade100 : Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badge.icon, size: 40, color: badge.achieved ? Colors.teal : Colors.grey),
              const SizedBox(height: 8),
              Text(badge.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(badge.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
