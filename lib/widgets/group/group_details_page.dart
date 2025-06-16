import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/models/contact.dart';
import 'package:fp_kelompok_1_ppb_c/models/group.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';

class GroupDetailsPage extends StatefulWidget {
  final Group group;
  const GroupDetailsPage({super.key, required this.group});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();

  Map<String, Contact> _memberProfiles = {};
  bool _isLoadingUsernames = true;

  String? _currentUserId;
  Uint8List? groupImage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _currentUserId = await _authService.getCurrentUserId();

    if (widget.group.groupImage != null && widget.group.groupImage!.isNotEmpty) {
      groupImage = Base64toImage.convert(widget.group.groupImage!);
    } else {
      groupImage = Uint8List(0);
    }

    await _fetchUserProfiles();
  }

  Future<void> _fetchUserProfiles() async {

    final memberMap = await _groupService.fetchGroupMemberProfiles(
      memberIds: widget.group.members,
      currentUserId: _currentUserId!,
    );

    setState(() {
      _memberProfiles = memberMap;
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
            Center(
              child: Column(
                children: [
                  Text(
                    widget.group.groupName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (groupImage != null && groupImage!.isNotEmpty)
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: MemoryImage(groupImage!),
                    )
                  else
                    const CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.group, size: 70, color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),


            _sectionCard(
              title: 'Members (${widget.group.members.length})',
              child: _isLoadingUsernames
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.group.members.map((memberId) {
                  final profile = _memberProfiles[memberId];
                  final isAdmin = widget.group.admins.contains(memberId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: profile != null
                        ? _userTile(profile, isAdmin: isAdmin)
                        : Text(memberId),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade100,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.chat_bubble),
          label: const Text('Go to Chat', style: TextStyle(fontSize: 16)),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/groupChat',
              arguments: widget.group,
            );
          },
        ),
      ),
    );
  }

  Widget _userTile(Contact profile, {bool isAdmin = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: (profile.profileImage != null && profile.profileImage!.isNotEmpty)
              ? MemoryImage(profile.profileImage!)
              : null,
          child: (profile.profileImage == null || profile.profileImage!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                if (profile.alias != profile.userName)
                  Text(
                    profile.alias,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                if (isAdmin) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(admin)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
