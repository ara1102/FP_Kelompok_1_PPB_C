import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';

class ContactEditForm extends StatefulWidget {
  final Map<String, dynamic> contact; // Changed to Map<String, dynamic>
  const ContactEditForm({super.key, required this.contact});

  @override
  State<ContactEditForm> createState() => _ContactEditFormState();
}

class _ContactEditFormState extends State<ContactEditForm> {
  late TextEditingController _aliasController;
  late Map<String, dynamic> _contactData; // Use this to store contact data

  @override
  void initState() {
    super.initState();
    _contactData = Map<String, dynamic>.from(widget.contact); // Copy the map
    _aliasController = TextEditingController(text: _contactData['alias'] ?? '');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _handleSaveContact() async {
    final newAlias = _aliasController.text.trim();
    if (newAlias.isEmpty) {
      _showSnackBar('Contact name cannot be empty');
      return;
    }

    try {
      await ContactService.instance.updateContact(
        AuthService.instance.getCurrentUserId(),
        _contactData['id'], // Pass the actual contactUserId
        {'alias': newAlias}, // Only update the alias
      );
      _showSnackBar('Contact updated successfully');
      Navigator.of(context).pop(); // Close the dialog
    } catch (e) {
      _showSnackBar('Failed to update contact: $e');
      print('Error updating contact: $e'); // For debugging
    }
  }

  Future<void> _openEditDialog() async {
    // Re-initialize controller text in case contact data changed externally
    _aliasController.text = (_contactData['alias'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Edit Contact '),
                TextSpan(
                  text: '@${_contactData['username'] ?? 'Unknown'}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          content: TextField(
            controller: _aliasController,
            decoration: const InputDecoration(labelText: 'Contact Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _handleSaveContact,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _openEditDialog,
      icon: const Icon(Icons.edit, color: Colors.deepPurple, size: 20.0),
    );
  }
}
