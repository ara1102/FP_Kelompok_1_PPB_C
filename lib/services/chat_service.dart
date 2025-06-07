import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CHAT MANAGEMENT ---

  /// Creates a new chat document in Firestore if one doesn't already exist
  /// between the two participants.
  /// Returns the chatId of the existing or newly created chat.
  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      // Ensure consistent chat ID generation by sorting participant IDs
      List<String> participants = [userId1, userId2]..sort();
      String chatId = participants.join('_'); // Example: "userId123_userId456"

      final chatDocRef = _firestore.collection('chats').doc(chatId);
      final chatDocSnapshot = await chatDocRef.get();

      if (!chatDocSnapshot.exists) {
        // Create new chat document
        await chatDocRef.set({
          'participants': participants,
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(), // Use server timestamp
        });
      }
      return chatId;
    } catch (e) {
      throw Exception('Failed to create or get chat: $e');
    }
  }

  /// Updates the last message and timestamp for a chat.
  Future<void> _updateLastMessage(
    String chatId,
    String lastMessage,
    String senderId,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessage,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last message: $e');
    }
  }

  /// Stream to get all chats for a specific user.
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  /// Get a specific chat document by its ID.
  Stream<DocumentSnapshot> getChatDetails(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  // --- MESSAGE MANAGEMENT ---

  /// Sends a message within a specific chat.
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      if (text.trim().isEmpty) {
        return; // Don't send empty messages
      }

      final messagesCollectionRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      // Add new message
      await messagesCollectionRef.add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
      });

      // Update the last message in the chat document
      await _updateLastMessage(chatId, text, senderId);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Retrieves all messages for a specific chat, ordered by timestamp.
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Or true for newest first
        .snapshots();
  }

  /// Edits an existing message.
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    try {
      if (newText.trim().isEmpty) {
        // Or handle deletion if newText is empty
        return;
      }
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'text': newText,
            'edited': true,
            // Optional: update an 'editedTimestamp'
            // 'editedTimestamp': FieldValue.serverTimestamp(),
          });
      // Potentially update lastMessage if this was the last message edited,
      // but this can be complex to track reliably without more logic.
      // For simplicity, it's often left as is, or only updated on new messages.
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Deletes a message.
  /// Note: Consider how you want to handle "deleting" messages.
  /// True deletion or marking as deleted?
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      // Potentially update lastMessage if this was the last message deleted.
      // This might involve fetching the new last message.
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Deletes an entire chat and its messages subcollection.
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the subcollection first
      final messagesSnapshot =
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the chat document itself
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}
