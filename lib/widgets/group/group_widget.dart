import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_list.dart';

class GroupWidget extends StatelessWidget {
  const GroupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GroupList());
  }
}
