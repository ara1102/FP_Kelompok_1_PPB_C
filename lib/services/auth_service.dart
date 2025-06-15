import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
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
    if (currentUser == null) {
      print('User not logged in');
      return;
    }

    if (image == null) {
      try {
        await _db.collection('Users').doc(currentUser.uid).update({
          'image': '',
        });
        print('Image field cleared');
      } catch (e) {
        print('Error clearing image field: $e');
      }
      return;
    }

    try {
      final base64Image = await ImagetoBase64.convert(image);
      print('Base64 length: ${base64Image.length} bytes');
      print('Base64 Image length: ${base64Image.length}');
      await _db.collection('Users').doc(currentUser.uid).update({
        'image': base64Image,
      });
      print('Image updated successfully');
    } catch (e) {
      print('Error updating image: $e');
    }
  }

  Future<String> getImageBase64(String userId) async {
    final doc = await _db.collection('Users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['image'] ?? '';
    }
    return '';
  }

  Future<String> registerEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Validasi username terlebih dahulu sebelum membuat akun
      final usernameExists = await _checkUsernameExists(username);
      if (usernameExists) {
        // Throw FirebaseAuthException untuk konsistensi dengan Firebase error lainnya
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'Username is already taken',
        );
      }

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
      rethrow; // Re-throw Firebase specific exceptions (termasuk custom username error)
    } catch (e) {
      // Convert generic errors ke FirebaseAuthException untuk konsistensi
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Method untuk mengecek apakah username sudah ada
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final querySnapshot =
          await _db
              .collection('Users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      // Error spesifik Firestore
      throw FirebaseAuthException(
        code: 'database-error',
        message: 'Failed to check username availability: ${e.message}',
      );
    } catch (e) {
      // Error umum lainnya
      throw FirebaseAuthException(
        code: 'network-error',
        message: 'Network error while checking username: ${e.toString()}',
      );
    }
  }

  // Utility method untuk handle error message di UI
  String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'username-already-in-use':
        return 'Username is already taken. Please choose another one.';
      case 'database-error':
        return 'Database connection error. Please try again.';
      case 'network-error':
        return 'Network error. Please check your connection.';
      case 'registration-failed':
        return e.message ?? 'Registration failed. Please try again.';
      default:
        return e.message ?? 'An unexpected error occurred.';
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
  static const int maxSizeInBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedFormats = ['jpg', 'jpeg', 'png'];

  /// Validasi ukuran file gambar
  static Future<bool> validateImageSize(File imageFile) async {
    final int fileSize = await imageFile.length();
    return fileSize <= maxSizeInBytes;
  }

  /// Validasi ekstensi format gambar
  static bool validateImageFormat(File imageFile) {
    final String extension = path
        .extension(imageFile.path)
        .toLowerCase()
        .replaceAll('.', '');
    return allowedFormats.contains(extension);
  }

  /// Gabungan validasi ukuran & format
  static Future<String?> validate(File imageFile) async {
    if (!validateImageFormat(imageFile)) {
      return 'Format gambar tidak didukung. Gunakan jpg, jpeg, atau png.';
    }

    if (!await validateImageSize(imageFile)) {
      return 'Ukuran gambar melebihi 10MB.';
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
  static Future<String> convert(
    ui.Image image, {
    int maxWidth = 800,
    int maxBase64SizeBytes = 1024 * 1024,
  }) async {
    if (image.width <= 0 || image.height <= 0) {
      return '';
    }

    // Ambil ByteData RGBA dari ui.Image
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) return '';

    // Buat image package Image dari raw bytes RGBA
    final img.Image baseImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: byteData.buffer,
      order: img.ChannelOrder.rgba, // karena pakai ui.ImageByteFormat.rawRgba
    );

    // Resize image jika lebarnya lebih dari maxWidth
    img.Image resizedImage = baseImage;
    if (image.width > maxWidth) {
      resizedImage = img.copyResize(baseImage, width: maxWidth);
    }

    // Mulai dengan kualitas tinggi dan turunkan secara bertahap
    int quality = 90;
    String base64Result = '';

    while (quality >= 10) {
      List<int> compressedBytes;

      // Gunakan JPEG untuk kompresi yang lebih baik
      if (quality < 90) {
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      } else {
        // Coba PNG terlebih dahulu dengan kualitas tinggi
        compressedBytes = img.encodePng(resizedImage);
      }

      // Convert ke base64
      base64Result = base64Encode(compressedBytes);

      // Cek ukuran base64 (dalam bytes, bukan karakter)
      final int base64SizeBytes = base64Result.length;

      if (base64SizeBytes <= maxBase64SizeBytes) {
        break;
      }

      // Jika masih terlalu besar, kurangi kualitas atau resize lebih lanjut
      if (quality > 10) {
        quality -= 10;
      } else {
        // Jika kualitas sudah minimum, resize gambar lebih kecil
        final int newWidth = (resizedImage.width * 0.8).round();
        if (newWidth > 100) {
          // Jangan terlalu kecil
          resizedImage = img.copyResize(resizedImage, width: newWidth);
          quality = 60; // Reset kualitas
        } else {
          break; // Sudah tidak bisa dikecilkan lagi
        }
      }
    }

    return base64Result;
  }
}
