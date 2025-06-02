import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';

class ContactEditForm extends StatefulWidget {
  final DocumentSnapshot contact;
  const ContactEditForm({super.key, required this.contact});

  @override
  State<ContactEditForm> createState() => _ContactEditFormState();
}

class _ContactEditFormState extends State<ContactEditForm> {
  late TextEditingController _aliasController;
  Map<String, dynamic>? contact;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController();
    _loadContactDetails();
  }

  Future<void> _loadContactDetails() async {
    try {
      final contactData = await ContactService.instance.getContactDetails(
        widget.contact,
      );
      setState(() {
        contact = contactData;
        _aliasController.text = contact?['alias'] ?? '';
      });
    } catch (e) {
      print('Error loading contact details: $e');
    }
  }

  Future<void> _showEditContactDialog() async {
    await _loadContactDetails();

    if (contact == null) return;

    _aliasController.text = contact!['alias'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Edit Contact '),
                TextSpan(
                  text: '@${contact!['userName']}',
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
              onPressed: () async {
                await ContactService.instance.updateContact(
                  AuthService.instance.getCurrentUserId(),
                  widget.contact.id,
                  {...contact!, 'alias': _aliasController.text},
                );
                Navigator.of(context).pop();
                await _loadContactDetails(); // Optional: refresh setelah update
              },
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
      onPressed: _showEditContactDialog,
      icon: const Icon(Icons.edit, color: Colors.deepPurple, size: 20.0),
    );
  }
}
