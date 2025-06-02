import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_card.dart';

class ContactList extends StatelessWidget {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ContactService.instance.getAllContacts(
        AuthService.instance.getCurrentUserId(),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List contacts = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              DocumentSnapshot contact = contacts[index];
              // String contactId = contact.id;

              return ContactCard(
                contact: contact,
              );
            },
          );
        } else {
          return const Text("No Contacts...");
        }
      },
    );
  }
}
