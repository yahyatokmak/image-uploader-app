import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static String? get currentUserId => _auth.currentUser?.uid;

  static bool get isAuthenticated => _auth.currentUser != null;

  static Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential;
    } catch (e) {
      throw Exception('Anonymous sign in failed: ${e.toString()}');
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      throw Exception('Account deletion failed: ${e.toString()}');
    }
  }
}
