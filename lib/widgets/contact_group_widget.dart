import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group_content.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact_content.dart';

class ContactAndGroupWidget extends StatelessWidget {
  const ContactAndGroupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity, // Ensure full width
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300, // Made shadow darker
                  spreadRadius: 1,
                  blurRadius: 5, // Increased blur for more visibility
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 4.0,
                right: 8.0,
                bottom: 4.0,
              ),
              child: Text(
                'Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD494),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(child: ContactContent()),
          Divider(height: 1, thickness: 1),
          Container(
            width: double.infinity, // Ensure full width
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300, // Made shadow darker
                  spreadRadius: 1,
                  blurRadius: 5, // Increased blur for more visibility
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 4.0,
                right: 8.0,
                bottom: 4.0,
              ), // Added left padding
              child: Text(
                'Groups',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD494),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0), // Added separation
          Expanded(child: GroupContent()),
        ],
      ),
    );
  }
}
