import 'package:flutter/material.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String groupName;

  const GroupChatAppBar({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(groupName, style: const TextStyle(fontSize: 20)));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
