import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'run_tracker_screen.dart';
import 'run_history_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:stride/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();

  double _weeklyGoal = 0.0;
  double _currentProgress = 0.0;
  bool _loading = true;
  bool _goalAlertShown = false;




  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final service = FirestoreService();
      final goal = await service.getWeeklyGoal();
      final runs = await service.getUserRuns();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));


      double weekDistance = 0.0;
      for (final run in runs) {
        if (run.timestamp.isAfter(weekStart)) {
          weekDistance += run.distanceKm;
        }
      }

      setState(() {
        _weeklyGoal = goal;
        _currentProgress = weekDistance;
        _loading = false;
      });

      // Show alert if goal is achieved
      if (weekDistance >= goal && !_goalAlertShown) {
        _goalAlertShown = true;
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('🎉 Goal Achieved!'),
              content: const Text('Congratulations! You reached your weekly goal.'),
              actions: [
                TextButton(
                  child: const Text('Awesome!'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        });
      }
    } catch (e) {
      print('Error loading weekly stats: $e');
      setState(() => _loading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
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

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard, color: Colors.teal),
            SizedBox(width: 8),
            Text('Stride'),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar + Welcome
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal,
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 28, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, $name!',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Let\'s achieve your weekly goal!',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Quote
                  Text(
                    '"The journey of a thousand miles begins with a single step."',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Weekly Goal Card with ProgressBar
                  _buildCard(
                    title: "🎯 Weekly Progress",
                    children: [
                      Text("Goal: ${_weeklyGoal.toStringAsFixed(1)} km"),
                      Text("Completed: ${_currentProgress.toStringAsFixed(1)} km"),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_weeklyGoal > 0) ? (_currentProgress / _weeklyGoal).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Start Run Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RunTrackerScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                 
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Run History'),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RunHistoryScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Stats'),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }
}
