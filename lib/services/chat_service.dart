import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CHAT MANAGEMENT ---

  /// Creates a new chat document in Firestore if one doesn't already exist
  /// between the two participants.
  /// Returns the chatId of the existing or newly created chat.
  Future<String> createOrGetChat(String userId1, String userId2) async {
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
  }

  /// Updates the last message and timestamp for a chat.
  Future<void> _updateLastMessage(
    String chatId,
    String lastMessage,
    String senderId,
  ) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessage,
      'lastTimestamp': FieldValue.serverTimestamp(),
      // Optional: you might want to store the sender of the last message
      // 'lastMessageSenderId': senderId,
    });
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
  }

  /// Deletes a message.
  /// Note: Consider how you want to handle "deleting" messages.
  /// True deletion or marking as deleted?
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
    // Potentially update lastMessage if this was the last message deleted.
    // This might involve fetching the new last message.
  }
}

// --- HOW TO USE (Example - typically in your UI/ViewModel layer) ---

/*
void main() async {
  // Ensure Firebase is initialized in your main.dart or an earlier point
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  final chatService = ChatService();
  final currentUserId = "userId123"; // Get this from your auth system
  final otherUserId = "userId456";

  // 1. Create or Get a Chat
  String chatId = await chatService.createOrGetChat(currentUserId, otherUserId);
  print("Chat ID: $chatId");

  // 2. Send a Message
  await chatService.sendMessage(chatId, currentUserId, "Hello from userId123!");
  await chatService.sendMessage(chatId, otherUserId, "Hi userId123!");

  // 3. Listen to Messages in a Chat
  chatService.getChatMessages(chatId).listen((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      print("--- Messages in chat $chatId ---");
      for (var doc in snapshot.docs) {
        final messageData = doc.data() as Map<String, dynamic>;
        print(
            "${messageData['senderId']}: ${messageData['text']} (Edited: ${messageData['edited']})");
      }
    } else {
      print("No messages in chat $chatId yet.");
    }
  });

  // 4. Listen to User's Chats
  chatService.getUserChats(currentUserId).listen((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      print("--- Chats for user $currentUserId ---");
      for (var doc in snapshot.docs) {
        final chatData = doc.data() as Map<String, dynamic>;
        print(
            "Chat with: ${chatData['participants'].firstWhere((id) => id != currentUserId)}, Last: ${chatData['lastMessage']}");
      }
    } else {
      print("No chats for user $currentUserId yet.");
    }
  });

  // 5. Edit a message (you'll need a messageId)
  // First, get a messageId (e.g., from the getChatMessages stream)
  // String messageIdToEdit = "some_message_id_from_firestore";
  // if (messageIdToEdit.isNotEmpty) {
  //   await chatService.editMessage(chatId, messageIdToEdit, "This message was edited!");
  // }

  // 6. Delete a message (you'll need a messageId)
  // String messageIdToDelete = "another_message_id_from_firestore";
  // if (messageIdToDelete.isNotEmpty) {
  //   await chatService.deleteMessage(chatId, messageIdToDelete);
  // }
}
*/
