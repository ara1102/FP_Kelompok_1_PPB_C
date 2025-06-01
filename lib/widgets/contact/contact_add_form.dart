import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';

class ContactAddForm extends StatefulWidget {
  const ContactAddForm({super.key});

  @override
  State<ContactAddForm> createState() => _ContactAddFormState();
}

class _ContactAddFormState extends State<ContactAddForm> {
  String userName = '';
  String contactName = '';

  void _showAddContactDialog() {
    userName = '';
    contactName = '';

    showDialog(
      context: context,
      builder: (context) {
        bool localLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _handleAddContact() async {
              final trimmedUserName = userName.trim();
              final trimmedContactName = contactName.trim();

              if (trimmedUserName.isEmpty || trimmedContactName.isEmpty) {
                _showSnackBar('Please fill all fields');
                return;
              }

              final currentUserId = AuthService.instance.getCurrentUserId();
              if (currentUserId == null) {
                _showSnackBar('Please login first');
                return;
              }

              setDialogState(() {
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
                    'userName': trimmedUserName,
                  });

                  _showSnackBar('Contact added successfully');
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('User does not exist or contact already added');
                }
              } catch (e) {
                print('Error adding contact: $e');
                _showSnackBar('Failed to add contact. Please try again.');
              } finally {
                setDialogState(() {
                  localLoading = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Add Contact'),
              content: Column(
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
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                    ),
                    enabled: !localLoading,
                  ),
                  const SizedBox(height: 20),
                  if (localLoading)
                    const CircularProgressIndicator()
                  else
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleAddContact,
                            child: const Text('Add Contact'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _showAddContactDialog,
      child: const Icon(Icons.add),
      tooltip: 'Add Contact',
    );
  }
}
