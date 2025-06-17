import 'dart:typed_data';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_delete.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_edit_form.dart';

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact; // Changed to Map<String, dynamic>
  final VoidCallback? onTap;

  const ContactCard({super.key, required this.contact, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Access data directly from the map
    var alias = contact['alias'] ?? '';
    var profileImageUrl = contact['profileImageUrl'];
    // final String contactUserId =
    //     contact['id']; // Get the actual userId of the contact

    Widget contactImage = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFFFE4BD), // Background color of the icon
        borderRadius: BorderRadius.circular(25.0), // Apply rounded corners
      ),
      child: const Icon(
        Icons.person,
        size: 30, // Set the icon size to fit within the rectangle
        color: Color(0xFFF4A44A), // You can change the color of the icon
      ),
    );

    Uint8List? imageProfile = Base64toImage.convert(profileImageUrl);

    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        imageProfile != null) {
      contactImage = ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: Image.memory(
          imageProfile,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFFFE4BD),
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: const Icon(
                Icons.people,
                size: 30,
                color: Color(0xFFF4A44A),
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      // Keep GestureDetector here for the whole card tap
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            contactImage,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alias, // Display the contact's alias
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // These will be replaced by IconButtons that open dialogs
            ContactEditForm(contact: contact),
            ContactDelete(contact: contact),
          ],
        ),
      ),
    );
  }
}
