import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  static final ContactService _instance = ContactService();
  static ContactService get instance => _instance;

  // New structure: contacts are fields within a single document per user
  // contacts/userId -> { contactId1: {alias: "...", username: "..."}, contactId2: {...} }

  /// Retrieves details for a specific contact from the new structure.
  /// `contactId` here refers to the actual userId of the contact.
  Future<Map<String, dynamic>> getContactDetails(
    String currentUserId,
    String contactUserId,
  ) async {
    final contactDoc =
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(currentUserId)
            .get();

    if (contactDoc.exists) {
      final contactsData = contactDoc.data() as Map<String, dynamic>;
      final contactData = contactsData[contactUserId] as Map<String, dynamic>?;

      if (contactData != null) {
        // Fetch the actual username from the Users collection
        final userData =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(contactUserId)
                .get();
        final userName = userData.data()?['username'] ?? contactUserId;

        return {
          'id': contactUserId, // The contact's actual userId
          'alias': contactData['alias'] ?? userName,
          'userId': contactUserId,
          'username': userName,
        };
      }
    }
    throw Exception(
      'Contact not found for user $currentUserId: $contactUserId',
    );
  }

  /// Stream to get all contacts for a specific user from the new structure.
  /// Returns a stream of a single DocumentSnapshot containing all contacts as fields.
  Stream<DocumentSnapshot> getAllContacts(String userId) {
    return FirebaseFirestore.instance
        .collection('contacts')
        .doc(userId)
        .snapshots();
  }

  /// Adds a contact to the current user's contact list and mutually to the target user's list.
  Future<void> addContact(
    String currentUserId,
    Map<String, dynamic> contactData,
  ) async {
    final targetUsername = contactData['username'];
    if (targetUsername == null) {
      throw Exception('Contact username is required.');
    }

    final String? targetUserId = await getUserIdByUsername(targetUsername);

    if (targetUserId == null) {
      throw Exception('User with username $targetUsername not found.');
    }

    // Prevent adding self
    if (currentUserId == targetUserId) {
      throw Exception('Cannot add yourself as a contact.');
    }

    // Add contact to current user's list
    final currentUserContactRef = FirebaseFirestore.instance
        .collection('contacts')
        .doc(currentUserId);
    await currentUserContactRef.set(
      {
        targetUserId: {
          'alias': contactData['alias'] ?? targetUsername,
          'addedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true), // Merge to add/update specific fields
    );

    // Mutual Contact Addition: Add current user to target user's contact list
    final targetUserContactRef = FirebaseFirestore.instance
        .collection('contacts')
        .doc(targetUserId);
    final currentUserDoc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserId)
            .get();
    final currentUsername = currentUserDoc.data()?['username'];

    if (currentUsername != null) {
      await targetUserContactRef.set({
        currentUserId: {
          'alias': currentUsername, // Use username as alias for mutual addition
          'addedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }
  }

  /// Get user ID by username from the Users collection
  /// Returns null if user not found.
  Future<String?> getUserIdByUsername(String userName) async {
    try {
      final userQuery =
          await FirebaseFirestore.instance
              .collection('Users')
              .where('username', isEqualTo: userName)
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.id;
      } else {
        return null; // User not found
      }
    } catch (e) {
      print('Error getting user ID by username: $e');
      return null;
    }
  }

  /// Check if a user exists globally by username
  Future<bool> userExistsGlobally(String userName) async {
    try {
      final userId = await getUserIdByUsername(userName);
      return userId != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if user already has this contact by username (using the new structure)
  Future<bool> isContactAlreadyAdded(String userId, String userName) async {
    final targetUserId = await getUserIdByUsername(userName);
    if (targetUserId == null) {
      return false; // User doesn't exist, so cannot be added as contact
    }

    final contactDoc =
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(userId)
            .get();

    if (contactDoc.exists) {
      final contactsData = contactDoc.data() as Map<String, dynamic>;
      return contactsData.containsKey(targetUserId);
    }
    return false;
  }

  /// Check if contact exists by document ID (using the new structure)
  /// `contactId` here refers to the actual userId of the contact.
  Future<bool> isContactExists(
    String currentUserId,
    String contactUserId,
  ) async {
    final contactDoc =
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(currentUserId)
            .get();
    if (contactDoc.exists) {
      final contactsData = contactDoc.data() as Map<String, dynamic>;
      return contactsData.containsKey(contactUserId);
    }
    return false;
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

  /// Updates a contact's alias (using the new structure).
  /// `contactUserId` here refers to the actual userId of the contact.
  Future<void> updateContact(
    String currentUserId,
    String contactUserId,
    Map<String, dynamic> contactData,
  ) async {
    final contactRef = FirebaseFirestore.instance
        .collection('contacts')
        .doc(currentUserId);
    await contactRef.update({
      '$contactUserId.alias': contactData['alias'],
      // You might want to update other fields like 'addedAt' if needed
    });
  }

  /// Deletes a contact from the current user's list (using the new structure).
  /// `contactUserId` here refers to the actual userId of the contact.
  Future<void> deleteContact(String currentUserId, String contactUserId) async {
    final contactRef = FirebaseFirestore.instance
        .collection('contacts')
        .doc(currentUserId);
    await contactRef.update({contactUserId: FieldValue.delete()});
  }

  /// Get contact document by username (for existing contacts) - adapted for new structure
  /// This will return the contact's userId if found.
  Future<String?> getContactUserIdByUsername(
    String currentUserId,
    String userName,
  ) async {
    final contactDoc =
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(currentUserId)
            .get();

    if (contactDoc.exists) {
      final contactsData = contactDoc.data() as Map<String, dynamic>;
      for (var entry in contactsData.entries) {
        if (entry.value is Map<String, dynamic> &&
            entry.value['username'] == userName) {
          return entry
              .key; // Return the contact's userId (which is the map key)
        }
      }
    }
    return null;
  }
}
