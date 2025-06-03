import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart'; // Assuming this is your auth service

class ChatScreen extends StatefulWidget {
  final DocumentSnapshot contact; // This is the document of the other user
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Map<String, dynamic> contactData;
  late String contactAlias;
  late String contactId;

  late ChatUser _currentUser;
  late ChatUser _otherUser;

  final List<ChatMessage> _messages = <ChatMessage>[]; // For initial load
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _chatRoomId;

  @override
  void initState() {
    super.initState();
    contactData = widget.contact.data() as Map<String, dynamic>;
    contactAlias = contactData['alias'] ?? 'Contact'; // Default alias if null
    contactId = widget.contact.id; // ID of the other user

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
      _chatRoomId = 'error_room';
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

    _chatRoomId = _generateChatRoomId(_currentUser.id, _otherUser.id);
    _loadInitialMessages(); // Load existing messages for initial display
  }

  String _generateChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _onSend(ChatMessage message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add(message.toJson());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    }
  }

  void _loadInitialMessages() {
    if (_chatRoomId == 'error_room')
      return; // Don't load if chatRoomId is invalid

    _firestore
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final loadedMessages =
                snapshot.docs
                    .map((doc) => ChatMessage.fromJson(doc.data()))
                    .toList();
            if (mounted) {
              setState(() {
                _messages
                    .clear(); // Clear before adding to prevent accumulation if called multiple times
                _messages.addAll(loadedMessages);
              });
            }
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error loading initial messages: ${error.toString()}',
                ),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser.id == 'error_user' || _chatRoomId == 'error_room') {
      return Scaffold(
        appBar: AppBar(title: Text(contactAlias)),
        body: const Center(
          child: Text("User not authenticated or chat room error."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(contactAlias)),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('chats')
                .doc(_chatRoomId)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          List<ChatMessage> displayMessages;

          if (snapshot.hasError) {
            // 1. Handle error state
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            // 2. Handle waiting state (stream is connecting)
            if (_messages.isEmpty) {
              // No initial messages loaded yet, show loader
              return const Center(child: CircularProgressIndicator());
            } else {
              // Show initially loaded messages while stream connects
              displayMessages = List<ChatMessage>.from(_messages);
            }
          } else if (snapshot.hasData) {
            // 3. Handle active stream state (has data, even if it's an empty list of docs)
            displayMessages =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Ensure 'user' field is correctly structured for ChatMessage.fromJson
                  // (existing comments about user field are good)
                  return ChatMessage.fromJson(data);
                }).toList();
          } else {
            // 4. Fallback / Other states (e.g., stream is done, none, or error already handled)
            // This usually means no messages if error is handled and not waiting.
            displayMessages = [];
          }

          return DashChat(
            currentUser: _currentUser,
            onSend: _onSend,
            messages: displayMessages, // Use the determined list
            messageOptions: const MessageOptions(
              showCurrentUserAvatar: true,
              showOtherUsersAvatar: true,
              // timeFormat: intl.DateFormat('HH:mm'), // Example
            ),
          );
        },
      ),
    );
  }
}
