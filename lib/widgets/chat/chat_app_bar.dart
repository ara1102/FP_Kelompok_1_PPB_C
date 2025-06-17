import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget contactImage;
  final String contactAlias;

  const ChatAppBar({
    super.key,
    required this.contactImage,
    required this.contactAlias,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF4A44A), // Warna hex F4A44A
      title: Row(
        children: [
          contactImage,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              contactAlias,
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
