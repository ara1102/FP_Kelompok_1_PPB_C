import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_list.dart';

class ContactWidget extends StatelessWidget {
  const ContactWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ContactList());
  }
}
