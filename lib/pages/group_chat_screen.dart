import 'dart:math'; // Import for random color generation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_chat_service.dart'; // Import GroupChatService
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart'; // Import GroupService for Group model and username fetching

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
        print('Error fetching username for $memberId: $e');
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

  void _showEditDeleteDialog(ChatMessage message) {
    if (message.user.id != _currentUser.id) {
      // Only allow editing/deleting own messages
      return;
    }

    final messageId = message.customProperties?['messageId'] as String?;
    if (messageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Message ID not found.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.of(context).pop(); // Close dialog
                  _showEditMessageDialog(message, messageId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.of(context).pop(); // Close dialog
                  _confirmDeleteMessage(messageId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMessageDialog(ChatMessage message, String messageId) {
    final TextEditingController _editController = TextEditingController(
      text: message.text,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(hintText: 'Enter new message'),
            maxLines: null, // Allow multiline input
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final newText = _editController.text.trim();
                if (newText.isNotEmpty) {
                  try {
                    await _groupChatService.editGroupMessage(
                      widget.group.id,
                      messageId,
                      newText,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message edited.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error editing message: ${e.toString()}',
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message cannot be empty.')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _groupChatService.deleteGroupMessage(
                    widget.group.id,
                    messageId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message deleted.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deleting message: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser.id == 'error_user') {
      return Scaffold(
        appBar: AppBar(title: Text(widget.group.groupName)),
        body: const Center(child: Text("User not authenticated.")),
      );
    }

    if (_groupMembersChatUsers.isEmpty && widget.group.members.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.group.groupName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group.groupName,
          style: const TextStyle(fontSize: 20), // Increased font size
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupChatService.getGroupChatMessages(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<ChatMessage> displayMessages = [];
          if (snapshot.hasData) {
            displayMessages =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final senderId = data['senderId'] as String;
                  final text = data['text'] as String;
                  final timestamp =
                      (data['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final messageId = doc.id;
                  final isEdited = data['edited'] as bool? ?? false;

                  // Get the ChatUser for the sender
                  final ChatUser senderUser =
                      _groupMembersChatUsers[senderId] ??
                      ChatUser(id: senderId, firstName: 'Unknown');

                  return ChatMessage(
                    user: senderUser,
                    text: text,
                    createdAt: timestamp,
                    customProperties: {
                      'messageId': messageId,
                      'edited': isEdited,
                    },
                  );
                }).toList();
            displayMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return DashChat(
            currentUser: _currentUser,
            onSend: _onSend,
            messages: displayMessages,
            messageOptions: MessageOptions(
              showCurrentUserAvatar: true,
              showOtherUsersAvatar: true,
              showOtherUsersName: false, // Disable default name display
              messageTextBuilder: (message, previousMessage, nextMessage) {
                final bool isMyMessage = message.user.id == _currentUser.id;
                final bool isEdited =
                    message.customProperties?['edited'] as bool? ?? false;
                final Color senderColor =
                    _memberColors[message.user.id] ??
                    Colors.black; // Get assigned color

                return GestureDetector(
                  onLongPress: () => _showEditDeleteDialog(message),
                  child: Column(
                    crossAxisAlignment:
                        isMyMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      // Display sender's name with random color for other users
                      if (!isMyMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            message.user.firstName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: senderColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMyMessage ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isEdited)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Edited',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
