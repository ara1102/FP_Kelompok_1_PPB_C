import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
// import 'package:firebase_core/firebase_core.dart';

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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfile(String userId) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .snapshots();
  }

  Future updateProfileImage(ui.Image? image) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    if (image == null) {
      await _db.collection('Users').doc(currentUser.uid).update({'image': ''});
      return;
    }
    final base64Image = await ImagetoBase64.convert(image);

    await _db.collection('Users').doc(currentUser.uid).update({
      'image': base64Image,
    });
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

class ImageValidator {
  static const int maxSizeInBytes = 400 * 1024; // 400 KB
  static const List<String> allowedFormats = ['jpg', 'jpeg', 'png'];

  /// Validasi ukuran file gambar
  static Future<bool> validateImageSize(File imageFile) async {
    final int fileSize = await imageFile.length();
    return fileSize <= maxSizeInBytes;
  }

  /// Validasi ekstensi format gambar
  static bool validateImageFormat(File imageFile) {
    final String extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    return allowedFormats.contains(extension);
  }

  /// Gabungan validasi ukuran & format
  static Future<String?> validate(File imageFile) async {
    if (!validateImageFormat(imageFile)) {
      return 'Format gambar tidak didukung. Gunakan jpg, jpeg, atau png.';
    }

    if (!await validateImageSize(imageFile)) {
      return 'Ukuran gambar melebihi 400KB.';
    }

    return null; // valid
  }
}

class Base64toImage {
  static convert(String base64String) {
    try {
      final Uint8List bytesImage = Base64Decoder().convert(base64String);
      return bytesImage;
    } catch (e) {
      return null;
    }
  }
}

class ImagetoBase64 {
  static Future<String> convert(ui.Image image) async {
    if (image.width <= 0 || image.height <= 0) {
      return '';
    }
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return '';
    final Uint8List bytes = byteData.buffer.asUint8List();
    return base64Encode(bytes);
  }
}
