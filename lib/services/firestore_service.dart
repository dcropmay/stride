import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/run_record.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save a run record 
  Future<void> saveRun(RunRecord run) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    await _db.collection('runs').add({
      'userId': uid,
      'distanceKm': run.distanceKm,
      'duration': run.duration,
      'pace': run.pace,
      'timestamp': Timestamp.fromDate(run.timestamp),
      'route': run.route
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
    });
  }

  /// current user runs
  Future<List<RunRecord>> getUserRuns() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final snapshot = await _db
        .collection('runs')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => RunRecord.fromMap(doc.data())).toList();
  }


  /// weekly goal 
  Future<double> getWeeklyGoal() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('weeklyGoal')) {
      return (doc['weeklyGoal'] as num).toDouble();
    }
    return 15.0; // default goal
  }

  /// Set weekly goal 
  Future<void> setWeeklyGoal(double goal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    await _db.collection('users').doc(uid).set(
      {'weeklyGoal': goal},
      SetOptions(merge: true), 
    );
  }
}

