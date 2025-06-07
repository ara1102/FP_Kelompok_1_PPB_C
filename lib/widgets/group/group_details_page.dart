import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';

class GroupDetailsPage extends StatefulWidget {
  final Group group;

  const GroupDetailsPage({super.key, required this.group});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final GroupService _groupService = GroupService.instance;
  Map<String, String> _memberUsernames = {};
  Map<String, String> _adminUsernames = {};
  bool _isLoadingUsernames = true;

  @override
  void initState() {
    super.initState();
    _fetchUsernames();
  }

  Future<void> _fetchUsernames() async {
    Map<String, String> memberUsernames = {};
    Map<String, String> adminUsernames = {};

    for (String memberId in widget.group.members) {
      try {
        String username = await _groupService.getUsernameByUserId(memberId);
        memberUsernames[memberId] = username;
      } catch (e) {
        memberUsernames[memberId] = 'Error: $e';
      }
    }

    for (String adminId in widget.group.admins) {
      try {
        String username = await _groupService.getUsernameByUserId(adminId);
        adminUsernames[adminId] = username;
      } catch (e) {
        adminUsernames[adminId] = 'Error: $e';
      }
    }

    setState(() {
      _memberUsernames = memberUsernames;
      _adminUsernames = adminUsernames;
      _isLoadingUsernames = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                widget.group.groupName,
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
              title: 'Members (${widget.group.members.length})',
              child:
                  _isLoadingUsernames
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            widget.group.members
                                .map(
                                  (memberId) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      _memberUsernames[memberId] ?? memberId,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
            ),

            const SizedBox(height: 16),

            // Admins Section
            _sectionCard(
              title: 'Admins (${widget.group.admins.length})',
              child:
                  _isLoadingUsernames
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            widget.group.admins
                                .map(
                                  (adminId) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      _adminUsernames[adminId] ?? adminId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.chat_bubble),
                label: Text('Go to Chat', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/groupChat',
                    arguments: widget.group,
                  );
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
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
