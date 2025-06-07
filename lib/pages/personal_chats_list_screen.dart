import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/chat_service.dart';
import 'package:fp_kelompok_1_ppb_c/pages/chat_screen.dart'; // For navigation

class PersonalChatsListScreen extends StatefulWidget {
  const PersonalChatsListScreen({super.key});

  @override
  State<PersonalChatsListScreen> createState() =>
      _PersonalChatsListScreenState();
}

class _PersonalChatsListScreenState extends State<PersonalChatsListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      return const Center(
        child: Text('User not logged in. Please log in to see your chats.'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Chats'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No personal chats yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = List<String>.from(chatData['participants']);
              final otherParticipantId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => 'Unknown User',
              );
              final lastMessage = chatData['lastMessage'] ?? 'No messages';

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('Users')
                        .doc(otherParticipantId)
                        .get(),
                builder: (context, userSnapshot) {
                  String displayName = otherParticipantId; // Default to ID
                  if (userSnapshot.connectionState == ConnectionState.done &&
                      userSnapshot.hasData &&
                      userSnapshot.data!.exists) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    displayName = userData['username'] ?? otherParticipantId;
                  }

                  return Dismissible(
                    key: Key(chatDoc.id), // Unique key for Dismissible
                    direction:
                        DismissDirection.endToStart, // Swipe from right to left
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text(
                              "Are you sure you want to delete this chat?",
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        await _chatService.deleteChat(chatDoc.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chat with $displayName deleted'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete chat: $e')),
                        );
                      }
                    },
                    child: ListTile(
                      title: Text(displayName),
                      subtitle: Text(lastMessage),
                      onTap: () async {
                        try {
                          final contactDoc =
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(otherParticipantId)
                                  .get();

                          if (contactDoc.exists) {
                            final contactDataMap = {
                              'id': otherParticipantId,
                              'alias':
                                  displayName, // Use the fetched display name
                              'username':
                                  displayName, // Assuming username is display name for chat
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ChatScreen(contact: contactDataMap),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Contact not found: $otherParticipantId',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error navigating to chat: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
