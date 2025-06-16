import 'dart:typed_data';

class Contact {
  final String contactId;
  final String userId;
  final String userName;
  final String alias;
  final Uint8List? profileImage;

  Contact(this.contactId, this.userId, this.userName, this.alias, this.profileImage);
}