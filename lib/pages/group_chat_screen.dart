import 'dart:math'; // Import for random color generation
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_chat_service.dart'; // Import GroupChatService
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart'; // Import GroupService for Group model and username fetching
import 'package:fp_kelompok_1_ppb_c/widgets/chat/group_chat_app_bar.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/group_chat_message_list.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/dialogs/confirm_delete_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/dialogs/edit_message_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/dialogs/message_options_dialog.dart';

class GroupChatScreen extends StatefulWidget {
  final Group group; // Pass the Group object

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late ChatUser _currentUser;
  final GroupChatService _groupChatService = GroupChatService();
  final GroupService _groupService =
      GroupService.instance; // For fetching usernames

  Map<String, ChatUser> _groupMembersChatUsers =
      {}; // To store ChatUser objects for all members
  final Map<String, Color> _memberColors =
      {}; // To store random colors for members
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    final firebaseUser = AuthService.instance.getCurrentUser();
    if (firebaseUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: Current user not found. Please log in."),
            ),
          );
        }
      });
      _currentUser = ChatUser(id: 'error_user', firstName: 'Error');
      return;
    }

    _currentUser = ChatUser(
      id: firebaseUser.uid,
      firstName: firebaseUser.displayName ?? firebaseUser.email ?? 'You',
    );

    _initializeGroupMembers();
  }

  Future<void> _initializeGroupMembers() async {
    Map<String, ChatUser> members = {};
    for (String memberId in widget.group.members) {
      try {
        String username = await _groupService.getUsernameByUserId(memberId);
        members[memberId] = ChatUser(id: memberId, firstName: username);
        _memberColors[memberId] =
            _generateRandomColor(); // Assign a random color
      } catch (e) {
        members[memberId] = ChatUser(id: memberId, firstName: 'Unknown User');
        _memberColors[memberId] = Colors.grey; // Default color for error
        // print('Error fetching username for $memberId: $e');
      }
    }
    setState(() {
      _groupMembersChatUsers = members;
    });
  }

  Color _generateRandomColor() {
    // Generate colors that are generally visible on both light and dark backgrounds.
    // Avoids very light colors (hard to see on white) and very dark colors (hard to see on black).
    // This range (50-200) aims for medium brightness.
    return Color.fromARGB(
      255,
      _random.nextInt(150) + 50, // R: 50-199
      _random.nextInt(150) + 50, // G: 50-199
      _random.nextInt(150) + 50, // B: 50-199
    );
  }

  Future<void> _onSend(ChatMessage message) async {
    if (_currentUser.id == 'error_user') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated. Cannot send message.'),
          ),
        );
      }
      return;
    }

    try {
      await _groupChatService.sendMessageToGroup(
        widget.group.id,
        message.user.id,
        message.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (_currentUser.id == 'error_user') {
      bodyContent = const Center(child: Text("User not authenticated."));
    } else if (_groupMembersChatUsers.isEmpty &&
        widget.group.members.isNotEmpty) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else {
      bodyContent = GroupChatMessageList(
        currentUser: _currentUser,
        groupId: widget.group.id,
        onSend: _onSend,
        onLongPressMessage: (message) {
          MessageOptionsDialog.show(
            context,
            message,
            _currentUser.id,
            (msg, msgId) => EditMessageDialog.show(
              context,
              msg,
              msgId,
              widget.group.id,
              _groupChatService.editGroupMessage, // Pass the specific function
            ),
            (msgId) => ConfirmDeleteDialog.show(
              context,
              msgId,
              widget.group.id,
              _groupChatService
                  .deleteGroupMessage, // Pass the specific function
            ),
          );
        },
        groupMembersChatUsers: _groupMembersChatUsers,
        memberColors: _memberColors,
      );
    }

    return Scaffold(
      appBar: GroupChatAppBar(groupName: widget.group.groupName),
      body: bodyContent,
    );
  }
}
