import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_card.dart';
import 'package:fp_kelompok_1_ppb_c/models/group.dart';

class GroupList extends StatelessWidget {
  const GroupList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.getCurrentUserId();

    return StreamBuilder<List<Group>>(
      stream: GroupService.instance.getUserGroupList(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load groups"));
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return const Center(child: Text("No groups found"));
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return GroupCard(groupModel: group);
          },
        );
      },
    );
  }
}
