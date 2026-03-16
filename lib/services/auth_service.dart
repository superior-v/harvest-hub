import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
  Future<User?> signIn(String email, String password) async {
    try {
      print("Signing in with: $email");

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User signed in: ${userCredential.user?.uid}");

      return userCredential.user;
    } catch (e) {
      print("Error during sign-in: $e");
      return null;
    }
  }





  Future<void> signOut() async {
    await _auth.signOut();
  }
}
