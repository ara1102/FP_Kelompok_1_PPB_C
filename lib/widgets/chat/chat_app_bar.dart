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
      title: Row(
        children: [
          contactImage,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              contactAlias,
              style: const TextStyle(fontSize: 20),
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
