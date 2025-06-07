import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/chat_service.dart'; // Import ChatService

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> contact; // Changed to Map<String, dynamic>
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String contactAlias;
  late String contactId; // This will be the actual userId of the contact

  late ChatUser _currentUser;
  late ChatUser _otherUser;

  final ChatService _chatService = ChatService(); // Instance of ChatService

  @override
  void initState() {
    super.initState();
    contactAlias = widget.contact['alias'] ?? 'Contact';
    contactId = widget.contact['id']; // Get the actual userId from the map

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
      _otherUser = ChatUser(id: contactId, firstName: contactAlias);
      return;
    }

    _currentUser = ChatUser(
      id: firebaseUser.uid,
      firstName: firebaseUser.displayName ?? firebaseUser.email ?? 'You',
    );

    _otherUser = ChatUser(
      id: contactId,
      firstName: contactAlias,
      // profileImage: contactData['profileImageUrl'],
    );

    _initializeChatRoom(); // Call async method to initialize chat room
  }

  String? _chatRoomId; // Made nullable

  Future<void> _initializeChatRoom() async {
    try {
      _chatRoomId = await _chatService.createOrGetChat(
        _currentUser.id,
        _otherUser.id,
      );
      setState(() {}); // Trigger rebuild after chatRoomId is set
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing chat: ${e.toString()}')),
        );
      }
      _chatRoomId = 'error_room'; // Indicate an error state
      setState(() {});
    }
  }

  Future<void> _onSend(ChatMessage message) async {
    if (_chatRoomId == null || _chatRoomId == 'error_room') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat is not ready yet. Please wait.')),
        );
      }
      return;
    }

    try {
      await _chatService.sendMessage(
        _chatRoomId!, // Use ! because we've checked for null
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
                    await _chatService.editMessage(
                      _chatRoomId!,
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
                  await _chatService.deleteMessage(_chatRoomId!, messageId);
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
        appBar: AppBar(title: Text(contactAlias)),
        body: const Center(child: Text("User not authenticated.")),
      );
    }

    if (_chatRoomId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(contactAlias)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chatRoomId == 'error_room') {
      return Scaffold(
        appBar: AppBar(title: Text(contactAlias)),
        body: const Center(child: Text("Failed to initialize chat room.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          contactAlias,
          style: const TextStyle(fontSize: 20), // Increased font size
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatMessages(
          _chatRoomId!,
        ), // Use ! because we've checked for null
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
                  final messageId = doc.id; // Get the message ID
                  final isEdited =
                      data['edited'] as bool? ?? false; // Get edited status

                  return ChatMessage(
                    user:
                        (senderId == _currentUser.id)
                            ? _currentUser
                            : _otherUser,
                    text: text,
                    createdAt: timestamp,
                    customProperties: {
                      'messageId': messageId,
                      'edited': isEdited,
                    },
                  );
                }).toList();
            // DashChat expects messages in reverse chronological order (newest first)
            displayMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return DashChat(
            currentUser: _currentUser,
            onSend: _onSend,
            messages: displayMessages,
            messageOptions: MessageOptions(
              showCurrentUserAvatar: true,
              showOtherUsersAvatar: true,
              showOtherUsersName: true, // Disable default name display
              messageTextBuilder: (message, previousMessage, nextMessage) {
                final bool isMyMessage = message.user.id == _currentUser.id;
                final bool isEdited =
                    message.customProperties?['edited'] as bool? ?? false;

                return GestureDetector(
                  onLongPress: () => _showEditDeleteDialog(message),
                  child: Column(
                    crossAxisAlignment:
                        isMyMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
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
