import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/pages/chat_screen.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_card.dart';

class ContactList extends StatelessWidget {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.getCurrentUserId();
    if (currentUserId.isEmpty) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: ContactService.instance.getAllContacts(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            snapshot.data!.data() == null) {
          return const Center(child: Text("No Contacts yet."));
        }

        // The contacts are now fields within the single DocumentSnapshot
        final Map<String, dynamic> contactsData =
            snapshot.data!.data() as Map<String, dynamic>;

        // Convert the map of contacts to a list of contact data for ListView.builder
        final List<Map<String, dynamic>> contacts = [];
        contactsData.forEach((contactUserId, contactInfo) {
          if (contactInfo is Map<String, dynamic>) {
            contacts.add({
              'id': contactUserId, // The actual userId of the contact
              'alias': contactInfo['alias'],
              'username':
                  contactInfo['username'], // Assuming username is stored or can be fetched
              'addedAt': contactInfo['addedAt'],
            });
          }
        });

        if (contacts.isEmpty) {
          return const Center(child: Text("No Contacts yet."));
        }

        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contactData = contacts[index];
            final String contactUserId = contactData['id'];
            final String alias =
                contactData['alias'] ?? contactUserId; // Use alias if available

            // Fetch the actual username from the Users collection for display
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(contactUserId)
                      .get(),
              builder: (context, userSnapshot) {
                String displayName = alias;
                if (userSnapshot.connectionState == ConnectionState.done &&
                    userSnapshot.hasData &&
                    userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  displayName = userData['username'] ?? alias;
                }

                // Now that ContactCard and ChatScreen accept Map<String, dynamic>,
                // we can pass the contactData directly, or enrich it with displayName.
                final Map<String, dynamic> enrichedContactData = {
                  'id': contactUserId,
                  'alias': alias,
                  'username':
                      displayName, // Use the fetched username for display
                  'addedAt': contactData['addedAt'],
                };

                return ContactCard(
                  contact: enrichedContactData, // Pass the enriched Map
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ChatScreen(contact: enrichedContactData),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
