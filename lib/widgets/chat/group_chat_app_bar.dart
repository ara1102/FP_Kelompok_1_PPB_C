import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/contact_avatar.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? groupImage;
  final String groupName;

  const GroupChatAppBar({super.key, required this.groupName, this.groupImage});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF4A44A),
      title: Row(
        children: [
          ContactAvatar(
            profileImageUrl: groupImage,
            size: 40, // Ukuran avatar grup
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              groupName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold, // Teks menjadi bold
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
