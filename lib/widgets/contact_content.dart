import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_list.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_add_form.dart';

class ContactContent extends StatelessWidget {
  const ContactContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ContactList(),
        Positioned(
          bottom: 16,
          right: 16,
          child: ContactAddForm(),
        ),
      ],
    );
  }
}
