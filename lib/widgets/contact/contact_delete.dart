import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';

class ContactDelete extends StatelessWidget {
  final Map<String, dynamic> contact; // Changed to Map<String, dynamic>

  const ContactDelete({super.key, required this.contact});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access data directly from the map
    final username = contact['username'] ?? 'Unknown User';
    final alias = contact['alias'] ?? 'No Alias';
    final contactUserId = contact['id']; // Get the actual userId of the contact

    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red, size: 20.0),
      onPressed: () {
        // Show delete confirmation dialog when the trash icon is pressed
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Contact'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete this contact?'),
                  const SizedBox(height: 10),
                  Text(
                    'Username: @$username',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Contact Name: $alias',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ContactService.instance.deleteContact(
                        AuthService.instance.getCurrentUserId(),
                        contactUserId, // Use the actual contactUserId
                      );
                      _showSnackBar(context, 'Contact deleted successfully');
                      Navigator.pop(context); // Close the dialog after deleting
                    } catch (e) {
                      _showSnackBar(context, 'Failed to delete contact: $e');
                      print('Error deleting contact: $e'); // For debugging
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
