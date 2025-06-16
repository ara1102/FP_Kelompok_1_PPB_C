import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';

class ContactAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final double size;

  const ContactAvatar({super.key, this.profileImageUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageProfile = Base64toImage.convert(profileImageUrl ?? '');

    if (imageProfile != null && imageProfile.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.memory(
          imageProfile,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6, // Adjust icon size relative to avatar size
        color: Colors.deepPurple,
      ),
    );
  }
}
