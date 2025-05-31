import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_delete.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_edit_form.dart';

class ContactCard extends StatelessWidget {
  final DocumentSnapshot contact;

  const ContactCard({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    var contactData = contact.data() as Map<String, dynamic>;
    var alias = contactData['alias'] ?? '';

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25.0),
            child: Image.network(
              // author.imageUrl ??
              '', // If imageUrl is null, it will fallback to empty string
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                // Return a rectangular icon when the image is not available
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // Background color of the icon
                    borderRadius: BorderRadius.circular(
                      25.0,
                    ), // Apply rounded corners to the icon container
                  ),
                  child: Icon(
                    Icons.people,
                    size: 30, // Set the icon size to fit within the rectangle
                    color: Colors.blue, // You can change the color of the icon
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 10),
          // Wrap the author text inside an Expanded widget to prevent overflow
          Expanded(
            child: Text(
              alias, // Display the author's alias
              maxLines: 1, // Limit the text to 2 lines
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          SizedBox(width: 10),
          ContactEditForm(
            contact: contact, // Pass the contact
          ),
          ContactDelete(contact: contact),
          // Edit form for the contact
          // AuthorEditForm and DeleteConfirmationDialog should be placed outside Expanded
          // AuthorEditForm(editAuthor: editAuthor, oldAuthor: author),
          // AuthorDeleteConfirmationDialog(
          //   author: author,
          //   onDelete: deleteAuthor,
          // ),
        ],
      ),
    );
  }
}
