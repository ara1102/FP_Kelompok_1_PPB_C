import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/models/group.dart';

class GroupSettingsDialog extends StatelessWidget {
  final Group group;
  final String currentUserId;

  const GroupSettingsDialog({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = group.admins.contains(currentUserId);
    final groupService = GroupService();

    void leaveGroup() async {
      await groupService.leaveGroup(groupId: group.id, userId: currentUserId);
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('You left the group')));
    }

    void deleteGroup() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Delete Group'),
              content: Text(
                'Are you sure you want to delete "${group.groupName}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete'),
                ),
              ],
            ),
      );
      if (confirm == true) {
        await groupService.deleteGroup(
          groupId: group.id,
          userId: currentUserId,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Group deleted')));
      }
    }

    void openEditDialog() async {
      Navigator.pop(context); // Close the settings dialog

      if (!group.admins.contains(currentUserId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only group admins can edit the group')),
        );
        return;
      }

      await showDialog(
        context: context,
        builder:
            (_) => GroupDialog(
              initialGroupId: group.id,
              currentUserId: currentUserId,
              initialGroupName: group.groupName,
              initialMembers: group.members,
              initialAdmins: group.admins,
              initialGroupImage: group.groupImage,
              onSubmit: (updatedName, updatedMembers, updatedAdmins) async {
                try {
                  await GroupService().updateGroup(
                    groupId: group.id,
                    userId: currentUserId,
                    newGroupName: updatedName,
                    newMembers: updatedMembers,
                    newAdmins: updatedAdmins,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group "$updatedName" updated!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                }
              },
            ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Group Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),

            ListTile(
              leading: Icon(
                Icons.edit,
                color: isAdmin ? Colors.blueAccent : Colors.grey,
              ),
              title: Text(
                'Edit Group',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? Colors.black87 : Colors.grey,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isAdmin ? Colors.blueAccent : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor:
                  isAdmin
                      ? Colors.blueAccent.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              onTap:
                  isAdmin
                      ? openEditDialog
                      : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Only group admins can edit the group',
                            ),
                          ),
                        );
                      },
            ),

            SizedBox(height: 12),

            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.orange),
              title: Text(
                'Leave Group',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.orange,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: Colors.orange.withOpacity(0.1),
              onTap: leaveGroup,
            ),

            SizedBox(height: 12),

            ListTile(
              leading: Icon(
                Icons.delete,
                color: isAdmin ? Colors.redAccent : Colors.grey,
              ),
              title: Text(
                'Delete Group',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? Colors.redAccent : Colors.grey,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isAdmin ? Colors.redAccent : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor:
                  isAdmin
                      ? Colors.redAccent.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              onTap:
                  isAdmin
                      ? deleteGroup
                      : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Only group admins can delete the group',
                            ),
                          ),
                        );
                      },
            ),

            SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
