import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

Future<String?> register(String name, String email, String password) async {
  final cred = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  await cred.user?.updateDisplayName(name);
  await cred.user?.reload();
  return null;
}


  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
