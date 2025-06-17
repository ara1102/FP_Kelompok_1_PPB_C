import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class EditMessageDialog {
  static void show(
    BuildContext context,
    ChatMessage message,
    String messageId,
    String chatRoomId,
    Function(String, String, String) onEditMessage,
  ) {
    final TextEditingController editController = TextEditingController(
      text: message.text,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Enter new message'),
            maxLines: null, // Allow multiline input
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  try {
                    await onEditMessage(chatRoomId, messageId, newText);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message edited.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message cannot be empty.')),
                    );
                  }
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFFF4A44A)),
              ),
            ),
          ],
        );
      },
    );
  }
}
