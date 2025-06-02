import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  static final ContactService _instance = ContactService();
  static ContactService get instance => _instance;

  Future<Map<String, dynamic>> getContactDetails(
    DocumentSnapshot contact,
  ) async {
    var contactData = contact.data() as Map<String, dynamic>;
    var userId = contactData['userId'] ?? '';
    var userData =
        (await FirebaseFirestore.instance.collection('Users').doc(userId).get())
                .data()
            as Map<String, dynamic>;
    var userName = userData['username'] ?? '';

    return {
      'id': contact.id,
      'alias': contactData['alias'] ?? '',
      'userId': userId,
      'userName': userName,
    };
  }

  Stream<QuerySnapshot> getAllContacts(String userId) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Contacts')
        .snapshots();
  }

  Future<void> addContact(
    String userId,
    Map<String, dynamic> contactData,
  ) async {
    // Get the target user's ID first
    final targetUserId = await getUserIdByUsername(contactData['userName']);

    // Add the userId to the contact data
    final completeContactData = {...contactData, 'userId': targetUserId};

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Contacts')
        .add(completeContactData);
  }

  /// Get user ID by username from the Users collection
  Future<String> getUserIdByUsername(String userName) async {
    final userQuery =
        await FirebaseFirestore.instance
            .collection('Users')
            .where('username', isEqualTo: userName)
            .limit(1)
            .get();

    if (userQuery.docs.isNotEmpty) {
      return userQuery.docs.first.id;
    } else {
      throw Exception('User with username $userName not found');
    }
  }

  /// Check if a user exists globally by username
  Future<bool> userExistsGlobally(String userName) async {
    try {
      await getUserIdByUsername(userName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user already has this contact by username
  Future<bool> isContactAlreadyAdded(String userId, String userName) async {
    final contactQuery =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Contacts')
            .where('userName', isEqualTo: userName)
            .limit(1)
            .get();

    return contactQuery.docs.isNotEmpty;
  }

  /// Check if contact exists by document ID
  Future<bool> isContactExists(String userId, String contactId) async {
    final contactDoc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Contacts')
            .doc(contactId)
            .get();
    return contactDoc.exists;
  }

  /// Main method to check if a contact can be added
  Future<bool> addContactExists(String userId, String userName) async {
    try {
      // First check if the user exists globally
      final userExists = await userExistsGlobally(userName);
      if (!userExists) {
        return false; // User doesn't exist
      }

      // Check if user is trying to add themselves
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();

      if (currentUserDoc.exists) {
        final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
        final currentUsername = currentUserData['username'] ?? '';
        if (currentUsername == userName) {
          return false; // Can't add yourself
        }
      }

      // Check if contact is already added
      final alreadyAdded = await isContactAlreadyAdded(userId, userName);
      if (alreadyAdded) {
        return false; // Contact already exists
      }

      return true; // Contact can be added
    } catch (e) {
      print('Error in addContactExists: $e');
      return false;
    }
  }

  Future<void> updateContact(
    String userId,
    String contactId,
    Map<String, dynamic> contactData,
  ) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Contacts')
        .doc(contactId)
        .update(contactData);
  }

  Future<void> deleteContact(String userId, String contactId) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Contacts')
        .doc(contactId)
        .delete();
  }

  /// Get contact document by username (for existing contacts)
  Future<DocumentSnapshot?> getContactByUsername(
    String userId,
    String userName,
  ) async {
    final contactQuery =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Contacts')
            .where('userName', isEqualTo: userName)
            .limit(1)
            .get();

    if (contactQuery.docs.isNotEmpty) {
      return contactQuery.docs.first;
    }
    return null;
  }
}
