import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class MessageOptionsDialog {
  static void show(
    BuildContext context,
    ChatMessage message,
    String currentUserId,
    Function(ChatMessage, String) onEdit,
    Function(String) onDelete,
  ) {
    if (message.user.id != currentUserId) {
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
                  onEdit(message, messageId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.of(context).pop(); // Close dialog
                  onDelete(messageId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
