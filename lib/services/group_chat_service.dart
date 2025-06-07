import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart'; // For getUsernameByUserId

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GroupService _groupService = GroupService.instance;

  // Sends a message within a specific group chat.
  Future<void> sendMessageToGroup(
    String groupId,
    String senderId,
    String text,
  ) async {
    try {
      if (text.trim().isEmpty) {
        return; // Don't send empty messages
      }

      final messagesCollectionRef = _firestore
          .collection('group_chats') // Changed to group_chats collection
          .doc(groupId)
          .collection('messages'); // Subcollection for group messages

      await messagesCollectionRef.add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
      });

      // Optionally, update a 'lastMessage' field in the group document
      // This would require adding a 'lastMessage' and 'lastMessageTimestamp'
      // to the Group model and updating it here. For now, we'll skip this
      // to keep it focused on core chat functionality.
    } catch (e) {
      throw Exception('Failed to send message to group: $e');
    }
  }

  // Retrieves all messages for a specific group chat, ordered by timestamp.
  Stream<QuerySnapshot> getGroupChatMessages(String groupId) {
    return _firestore
        .collection('group_chats') // Changed to group_chats collection
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Edits an existing message in a group chat.
  Future<void> editGroupMessage(
    String groupId,
    String messageId,
    String newText,
  ) async {
    try {
      if (newText.trim().isEmpty) {
        return;
      }
      await _firestore
          .collection('group_chats') // Changed to group_chats collection
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'text': newText, 'edited': true});
    } catch (e) {
      throw Exception('Failed to edit group message: $e');
    }
  }

  // Deletes a message in a group chat.
  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    try {
      await _firestore
          .collection('group_chats') // Changed to group_chats collection
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete group message: $e');
    }
  }

  // Fetches username by userId, reusing GroupService's method
  Future<String> getUsernameByUserId(String userId) async {
    return await _groupService.getUsernameByUserId(userId);
  }
}
