import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fp_kelompok_1_ppb_c/services/group_chat_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/chat/contact_avatar.dart';

// Helper function to decode the string safely
Uint8List? _decodeBase64(String base64String) {
  try {
    String pureBase64 = base64String.split(',').last;
    return base64Decode(pureBase64);
  } catch (e) {
    return null;
  }
}

class GroupChatMessageList extends StatelessWidget {
  final ChatUser currentUser;
  final String groupId;
  final Function(ChatMessage) onSend;
  final Function(ChatMessage) onLongPressMessage;
  final Map<String, ChatUser> groupMembersChatUsers;
  final Map<String, Color> memberColors;

  final GroupChatService _groupChatService = GroupChatService();

  GroupChatMessageList({
    super.key,
    required this.currentUser,
    required this.groupId,
    required this.onSend,
    required this.onLongPressMessage,
    required this.groupMembersChatUsers,
    required this.memberColors,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupChatService.getGroupChatMessages(groupId),
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

                final ChatUser senderUser =
                    groupMembersChatUsers[senderId] ??
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
          currentUser: currentUser,
          onSend: onSend,
          messages: displayMessages,
          messageOptions: MessageOptions(
            currentUserContainerColor: Color.fromARGB(1000, 255, 199, 96),

            showCurrentUserAvatar: true,
            showOtherUsersAvatar: true,
            showOtherUsersName: false,
            messageTextBuilder: (message, previousMessage, nextMessage) {
              final bool isMyMessage = message.user.id == currentUser.id;
              final bool isEdited =
                  message.customProperties?['edited'] as bool? ?? false;
              final Color senderColor =
                  memberColors[message.user.id] ?? Colors.black;

              return GestureDetector(
                onLongPress: () => onLongPressMessage(message),
                child: Column(
                  crossAxisAlignment:
                      isMyMessage
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
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
                      // style: TextStyle(
                      //   color: isMyMessage ? Colors.white : Colors.black,
                      // ),
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
            avatarBuilder: (
              ChatUser user,
              Function? onPressAvatar,
              Function? onLongPressAvatar,
            ) {
              final base64String =
                  user.customProperties?['base64Image'] as String?;

              if (base64String != null && base64String.isNotEmpty) {
                final imageBytes = _decodeBase64(base64String);
                if (imageBytes != null) {
                  return InkWell(
                    onTap: () => onPressAvatar?.call(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ContactAvatar(
                        profileImageUrl: base64String,
                        size: 40,
                      ),
                    ),
                  );
                }
              }

              return InkWell(
                onTap: () => onPressAvatar?.call(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ContactAvatar(profileImageUrl: null, size: 40),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
