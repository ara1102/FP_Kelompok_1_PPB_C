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
    var profileImageUrl = contact['profileImageUrl'] as String?;
    // final String contactUserId =
    //     contact['id']; // Get the actual userId of the contact

    Widget contactImage = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.deepPurple[50], // Background color of the icon
        borderRadius: BorderRadius.circular(25.0), // Apply rounded corners
      ),
      child: const Icon(
        Icons.person_2,
        size: 30, // Set the icon size to fit within the rectangle
        color: Colors.deepPurple, // You can change the color of the icon
      ),
    );

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      contactImage = ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: Image.network(
          profileImageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: const Icon(
                Icons.people,
                size: 30,
                color: Colors.deepPurple,
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
