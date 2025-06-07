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
        body: const Center(
          child:
              CircularProgressIndicator(), // Show loading while chat room initializes
        ),
      );
    }

    if (_chatRoomId == 'error_room') {
      return Scaffold(
        appBar: AppBar(title: Text(contactAlias)),
        body: const Center(child: Text("Failed to initialize chat room.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(contactAlias)),
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
                  // Handle potential null timestamp
                  final timestamp =
                      (data['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();

                  return ChatMessage(
                    user:
                        (senderId == _currentUser.id)
                            ? _currentUser
                            : _otherUser,
                    text: text,
                    createdAt: timestamp,
                  );
                }).toList();
            // DashChat expects messages in reverse chronological order (newest first)
            displayMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return DashChat(
            currentUser: _currentUser,
            onSend: _onSend,
            messages: displayMessages,
            messageOptions: const MessageOptions(
              showCurrentUserAvatar: true,
              showOtherUsersAvatar: true,
            ),
          );
        },
      ),
    );
  }
}
