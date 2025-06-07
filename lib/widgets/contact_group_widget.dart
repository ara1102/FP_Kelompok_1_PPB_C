import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group_content.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact_content.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact/contact_add_form.dart'; // Import ContactAddForm

class ContactAndGroupWidget extends StatelessWidget {
  const ContactAndGroupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
          Expanded(child: ContactContent()),
          Divider(height: 1, thickness: 1),
          Expanded(child: GroupContent()),
        ],
      ),
    );
  }
}
