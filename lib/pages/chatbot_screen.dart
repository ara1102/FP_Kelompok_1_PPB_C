import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final Gemini gemini = Gemini.instance;

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'You');
  final ChatUser _otherUser = ChatUser(id: '2', firstName: 'Bot');

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[]; // For typing indicator

  @override
  void initState() {
    super.initState();
    // Add an initial message
    _messages.add(
      ChatMessage(
        text: 'Hello! How can I help you today?',
        user: _otherUser,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashChat(
        currentUser: _currentUser,
        onSend: _sendMessage,
        messages: _messages,
        typingUsers: _typingUsers,
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: "Type a message...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
        messageOptions: const MessageOptions(
          currentUserContainerColor: Color.fromARGB(1000, 255, 199, 96),
          currentUserTextColor: Color.fromARGB(232, 0, 0, 0),
          showCurrentUserAvatar: true,
          showTime: true,
        ),
      ),
    );
  }

  void _sendMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
      _typingUsers.add(_otherUser);
    });

    List<Content> geminiHistory =
        _messages.reversed.map((chatMsg) {
          String role = (chatMsg.user.id == _currentUser.id) ? 'user' : 'model';
          return Content(
            role: role,
            parts: [Part.text(chatMsg.text)], // Ensure 'Part.text' is correct
          );
        }).toList();

    gemini
        .chat(geminiHistory)
        .then((response) {
          String? aiResponseText = response?.output;

          if (aiResponseText != null && aiResponseText.isNotEmpty) {
            ChatMessage aiChatMessage = ChatMessage(
              text: aiResponseText,
              user: _otherUser,
              createdAt: DateTime.now(),
            );
            setState(() {
              _messages.insert(0, aiChatMessage);
            });
          } else {
            ChatMessage errorMessage = ChatMessage(
              text: "I'm not sure how to respond to that right now.",
              user: _otherUser,
              createdAt: DateTime.now(),
            );
            setState(() {
              _messages.insert(0, errorMessage);
            });
          }
        })
        .catchError((e) {
          ChatMessage errorMessage = ChatMessage(
            text:
                "Sorry, something went wrong. Please try again. Error: ${e.toString()}",
            user: _otherUser,
            createdAt: DateTime.now(),
          );
          setState(() {
            _messages.insert(0, errorMessage);
          });
        })
        .whenComplete(() {
          setState(() {
            _typingUsers.remove(_otherUser);
          });
        });
  }
}
