import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';

class ContactDelete extends StatelessWidget {
  final DocumentSnapshot contact;

  const ContactDelete({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        final contactData = await ContactService.instance.getContactDetails(
          contact,
        );
        // Show delete confirmation dialog when the trash icon is pressed
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Are you sure to delete this contact?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'username: ${contactData['userName']}',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                  ),
                  Text(
                    'contact name: ${contactData['alias']}',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                  ),
                ],
              ),
              actions: [
                // "Yes" button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ContactService.instance.deleteContact(
                      AuthService.instance.getCurrentUserId(),
                      contact.id,
                    );
                    Navigator.pop(context); // Close the dialog after deleting
                  },
                  child: Text('Delete'),
                ),
                // "No" button
              ],
            );
          },
        );
      },
    );
  }
}
