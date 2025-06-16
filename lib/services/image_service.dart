import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

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