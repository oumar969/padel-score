import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<String> getUserId() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    return user.uid;
  }
}
