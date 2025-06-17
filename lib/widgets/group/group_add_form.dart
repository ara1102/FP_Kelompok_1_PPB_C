import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';
import 'group_dialog.dart';

class GroupAddForm extends StatelessWidget {
  const GroupAddForm({Key? key}) : super(key: key);

  void _openCreateGroupDialog(BuildContext context) {
    final currentUserId = AuthService.instance.getCurrentUserId();
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a group.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => GroupDialog(
            currentUserId: currentUserId,
            onSubmit: (groupName, memberIds, adminIds) async {
              try {
                await GroupService().createGroup(
                  groupName: groupName,
                  creatorId: currentUserId,
                  contactUserIds: memberIds,
                  adminIds: adminIds,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group "$groupName" created!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFF4A44A),
      heroTag: 'group-fab',
      onPressed: () => _openCreateGroupDialog(context),
      child: const Icon(Icons.group_add, color: Colors.black),
      tooltip: 'Create Group',
    );
  }
}
