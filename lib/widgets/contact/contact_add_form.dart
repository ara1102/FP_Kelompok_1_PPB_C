import 'package:cloud_firestore/cloud_firestore.dart'; // Import FirebaseFirestore
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/chat_service.dart'; // Import ChatService

class ContactAddForm extends StatefulWidget {
  const ContactAddForm({super.key});

  @override
  State<ContactAddForm> createState() => _ContactAddFormState();
}

class _ContactAddFormState extends State<ContactAddForm> {
  String userName = '';
  String contactName = '';
  bool localLoading = false; // Moved localLoading to widget state
  final ChatService _chatService = ChatService(); // Instantiate ChatService

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _handleAddContact() async {
    final trimmedUserName = userName.trim();
    final trimmedContactName = contactName.trim();

    if (trimmedUserName.isEmpty || trimmedContactName.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    final currentUserId = AuthService.instance.getCurrentUserId();

    setState(() {
      localLoading = true;
    });

    try {
      final addable = await ContactService.instance.addContactExists(
        currentUserId,
        trimmedUserName,
      );

      if (addable) {
        await ContactService.instance.addContact(currentUserId, {
          'alias': trimmedContactName,
          'username': trimmedUserName, // Changed to 'username'
        });

        // Get the newly added contact's user ID
        final userDoc =
            await FirebaseFirestore.instance
                .collection('Users') // Changed to 'Users'
                .where(
                  'username',
                  isEqualTo: trimmedUserName,
                ) // Changed to 'username'
                .get();

        if (userDoc.docs.isNotEmpty) {
          final newContactId = userDoc.docs.first.id;

          // Create chat room
          await _chatService.createOrGetChat(currentUserId, newContactId);
        }

        _showSnackBar('Contact added successfully');
        Navigator.of(context).pop(); // Close the dialog
      } else {
        _showSnackBar('User does not exist or contact already added');
      }
    } catch (e) {
      print('Error adding contact: $e');
      _showSnackBar('Failed to add contact. Please try again.');
    } finally {
      setState(() {
        localLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          onChanged: (value) => userName = value,
          decoration: const InputDecoration(labelText: 'Username'),
          enabled: !localLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => contactName = value,
          decoration: const InputDecoration(labelText: 'Add Nickname'),
          enabled: !localLoading,
        ),
        const SizedBox(height: 24), // Add some space before buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed:
                  localLoading
                      ? null
                      : () {
                        Navigator.of(context).pop();
                      },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: localLoading ? null : _handleAddContact,
              child:
                  localLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Contact'),
            ),
          ],
        ),
      ],
    );
  }
}
