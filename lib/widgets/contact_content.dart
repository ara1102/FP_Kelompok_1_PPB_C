import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_list.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_add_form.dart';

class ContactContent extends StatelessWidget {
  const ContactContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ContactList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF4A44A),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const AlertDialog(
                title: Text('Add New Contact'),
                content: SingleChildScrollView(child: ContactAddForm()),
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
