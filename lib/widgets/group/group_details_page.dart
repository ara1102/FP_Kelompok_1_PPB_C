import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';

class GroupDetailsPage extends StatelessWidget {
  final Group group;

  const GroupDetailsPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                group.groupName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Members Section
            _sectionCard(
              title: 'Members (${group.members.length})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: group.members.map((member) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(member, style: TextStyle(fontSize: 16)),
                )).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Admins Section
            _sectionCard(
              title: 'Admins (${group.admins.length})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: group.admins.map((admin) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(admin, style: TextStyle(fontSize: 16, color: Colors.blueAccent)),
                )).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Chat Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.chat_bubble),
                label: Text('Go to Chat', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.pushNamed(context, '/groupChat', arguments: group);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              )),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
