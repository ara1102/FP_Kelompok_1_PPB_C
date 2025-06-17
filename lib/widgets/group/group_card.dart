import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_settings_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_details_page.dart'; // import new dialog
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';
import 'package:fp_kelompok_1_ppb_c/models/group.dart';

class GroupCard extends StatelessWidget {
  final Group groupModel;

  const GroupCard({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    final name = groupModel.groupName;
    final members = groupModel.members;
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final groupImage = groupModel.groupImage;

    Uint8List? imageProfile;
    if (groupImage != null && groupImage.isNotEmpty) {
      imageProfile = Base64toImage.convert(groupImage);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => GroupDetailsPage(group: groupModel),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(25.0),
            child:
                imageProfile != null
                    ? Image.memory(
                      imageProfile,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _fallbackGroupIcon();
                      },
                    )
                    : _fallbackGroupIcon(),
          ),
          title: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Members: ${members.length}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => GroupSettingsDialog(
                      group: groupModel,
                      currentUserId: currentUserId,
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _fallbackGroupIcon() {
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Color(0xFFFFE4BD),
      borderRadius: BorderRadius.circular(25.0),
    ),
    child: const Icon(Icons.group, color: Color(0xFFF4A44A), size: 30),
  );
}
