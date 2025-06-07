import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService();
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream onAuthStateChanged() {
    return _auth.authStateChanges();
  }

  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? '';
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = getCurrentUserId();
    if (uid.isEmpty) return null;

    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> updateUsername(String username, User currentUser) async {
    await currentUser.updateDisplayName(username);
    await currentUser.reload();
  }

  Future<String> registerEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      final response = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('Users').doc(response.user!.uid).set({
        'username': username,
      });

      await updateUsername(username, response.user!);
      return response.user?.uid ?? '';
    } on FirebaseAuthException {
      rethrow; // Re-throw Firebase specific exceptions
    } catch (e) {
      throw Exception('Failed to register: $e'); // Generic error
    }
  }

  Future<String> loginEmail(String email, String password) async {
    try {
      final response = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return response.user?.uid ?? '';
    } on FirebaseAuthException {
      rethrow; // Re-throw Firebase specific exceptions
    } catch (e) {
      throw Exception('Failed to login: $e'); // Generic error
    }
  }

  logout() async {
    await _auth.signOut();
  }
}

class NameValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return "Username can't be empty";
    }
    if (value.length < 2) {
      return "Username must be at least 2 characters long";
    }
    if (value.length > 20) {
      return "Username must be less than 20 characters long";
    }
    return null;
  }
}

class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return "Email can't be empty";
    }
    if (!value.contains('@')) {
      return "Email must contain an @ symbol";
    }
    return null;
  }
}

class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return "Password can't be empty";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters long";
    }
    return null;
  }
}
