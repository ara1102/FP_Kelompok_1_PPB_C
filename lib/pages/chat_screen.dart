import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/chat_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/chat_app_bar.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/chat_message_list.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/dialogs/confirm_delete_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/dialogs/edit_message_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/dialogs/message_options_dialog.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/contact_avatar.dart'; // New import

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> contact; // Changed to Map<String, dynamic>
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String contactAlias;
  late String contactId; // This will be the actual userId of the contact
  late String contactProfileImageBase64;

  late ChatUser _currentUser;
  late ChatUser _otherUser;

  final ChatService _chatService = ChatService(); // Instance of ChatService

  @override
  void initState() {
    super.initState();
    contactAlias = widget.contact['alias'] ?? 'Contact';
    contactId = widget.contact['id']; // Get the actual userId from the map
    contactProfileImageBase64 = widget.contact['profileImageUrl'];

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
      customProperties: {}, // Initialize as empty map
    );

    _otherUser = ChatUser(
      id: contactId,
      firstName: contactAlias,
      // profileImage: contactData['profileImageUrl'],
      customProperties: {'base64Image': contactProfileImageBase64},
    );

    _fetchCurrentUserProfileImage(); // Fetch current user's profile image
    _initializeChatRoom(); // Call async method to initialize chat room
  }

  String? _chatRoomId; // Made nullable

  Future<void> _fetchCurrentUserProfileImage() async {
    try {
      final currentUserImageBase64 = await AuthService.instance.getImageBase64(
        _currentUser.id,
      );
      if (mounted) {
        setState(() {
          _currentUser = ChatUser(
            id: _currentUser.id,
            firstName: _currentUser.firstName,
            customProperties: {'base64Image': currentUserImageBase64},
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching current user profile image: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

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
    Widget bodyContent;
    if (_currentUser.id == 'error_user') {
      bodyContent = const Center(child: Text("User not authenticated."));
    } else if (_chatRoomId == null) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_chatRoomId == 'error_room') {
      bodyContent = const Center(
        child: Text("Failed to initialize chat room."),
      );
    } else {
      bodyContent = ChatMessageList(
        currentUser: _currentUser,
        otherUser: _otherUser,
        chatRoomId: _chatRoomId!,
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
              _chatRoomId!,
              _chatService.editMessage, // Pass the specific function
            ),
            (msgId) => ConfirmDeleteDialog.show(
              context,
              msgId,
              _chatRoomId!,
              _chatService.deleteMessage, // Pass the specific function
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: ChatAppBar(
        contactImage: ContactAvatar(
          profileImageUrl: widget.contact['profileImageUrl'],
          size: 40, // Adjust size as needed
        ),
        contactAlias: contactAlias,
      ),
      body: bodyContent,
    );
  }
}
