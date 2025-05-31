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
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Contacts')
        .add(contactData);
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
}
