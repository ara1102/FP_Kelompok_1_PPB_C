import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_list.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_add_form.dart';

class GroupContent extends StatelessWidget {
  const GroupContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GroupList(),
        Positioned(
          bottom: 16,
          right: 16,
          child: GroupAddForm(),
        ),
      ],
    );
  }
}
