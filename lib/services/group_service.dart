import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:fp_kelompok_1_ppb_c/models/contact.dart';
import 'package:fp_kelompok_1_ppb_c/models/group.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';

class GroupService {
  static final GroupService _instance = GroupService();
  static GroupService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  final _contactService = ContactService();

  Future<String> createGroup({
    required String groupName,
    required String creatorId,
    required List<String> contactUserIds,
    required List<String> adminIds,
    ui.Image? groupImage,
  }) async {
    final allMembers = [...contactUserIds, creatorId];
    final allAdmins = adminIds.contains(creatorId)
        ? adminIds
        : [...adminIds, creatorId];

    String? base64Image;
    if (groupImage != null) {
      base64Image = await ImagetoBase64.convert(groupImage);
    }

    final groupData = {
      'groupName': groupName,
      'createdBy': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
      'members': allMembers,
      'admins': allAdmins,
      'groupImage': base64Image ?? '',
    };

    final groupDoc = await _firestore.collection('Groups').add(groupData);
    return groupDoc.id;
  }

  Future<String> getUsernameByUserId(String userId) async {
    try {
      final doc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['username'] ?? 'Unknown';
      } else {
        throw Exception('User with ID $userId not found');
      }
    } catch (e) {
      throw Exception('Failed to get username for userId $userId: $e');
    }
  }

  // Read User Groups Stream
  Stream<List<Group>> getUserGroupList(String userId) {
    return _firestore
        .collection('Groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Group.fromDoc(doc))
        .toList());
  }

  // Delete Group (For Admin)
  Future<void> deleteGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _firestore.collection('Groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    if (!groupSnapshot.exists) {
      throw Exception('Group does not exist');
    }

    final data = groupSnapshot.data()!;
    final List<String> admins = List<String>.from(data['admins'] ?? []);

    if (!admins.contains(userId)) {
      throw Exception('Only admins can delete the group');
    }

    await groupRef.delete();
  }

// Update group info (for Admin)
  Future<void> updateGroup({
    required String groupId,
    required String userId,
    String? newGroupName,
    List<String>? newMembers,
    List<String>? newAdmins,
    ui.Image? groupImage,
  }) async {
    final groupRef = _firestore.collection('Groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    if (!groupSnapshot.exists) {
      throw Exception('Group does not exist');
    }

    final data = groupSnapshot.data()!;
    final List<String> admins = List<String>.from(data['admins'] ?? []);

    if (!admins.contains(userId)) {
      throw Exception('Only admins can update the group');
    }

    final updateData = <String, dynamic>{};
    if (newGroupName != null) updateData['groupName'] = newGroupName;
    if (newMembers != null) updateData['members'] = newMembers;
    if (newAdmins != null) updateData['admins'] = newAdmins;

    await groupRef.update(updateData);
  }

// Leave group - any member can leave
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _firestore.collection('Groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    if (!groupSnapshot.exists) {
      throw Exception('Group does not exist');
    }

    final data = groupSnapshot.data()!;
    final List<String> members = List<String>.from(data['members'] ?? []);
    final List<String> admins = List<String>.from(data['admins'] ?? []);

    if (!members.contains(userId)) {
      throw Exception('User is not a member of this group');
    }

    // Remove user from members list
    await groupRef.update({
      'members': FieldValue.arrayRemove([userId]),
    });

    // If user is admin, remove from admins list too
    if (admins.contains(userId)) {
      await groupRef.update({
        'admins': FieldValue.arrayRemove([userId]),
      });

      final updatedGroupSnapshot = await groupRef.get();
      final updatedData = updatedGroupSnapshot.data()!;
      final List<String> updatedAdmins = List<String>.from(updatedData['admins'] ?? []);
      final List<String> updatedMembers = List<String>.from(updatedData['members'] ?? []);

      // If no admins left but still members present, assign random member as admin
      if (updatedAdmins.isEmpty && updatedMembers.isNotEmpty) {
        updatedMembers.shuffle();
        final newAdmin = updatedMembers.first;
        await groupRef.update({
          'admins': FieldValue.arrayUnion([newAdmin]),
        });
      }
    }

    // If after leaving, no members remain, delete the group
    final afterLeaveSnapshot = await groupRef.get();
    final afterLeaveData = afterLeaveSnapshot.data()!;
    final List<String> afterMembers = List<String>.from(afterLeaveData['members'] ?? []);

    if (afterMembers.isEmpty) {
      await groupRef.delete();
    }
  }

  Future updateGroupImage({
    required String groupId,
    required String userId,
    ui.Image? image,
  }) async {
    final groupRef = _firestore.collection('Groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    if (!groupSnapshot.exists) {
      throw Exception('Group does not exist');
    }

    try {
      String imageData = '';
      if (image != null) {
        imageData = await ImagetoBase64.convert(image);
        print('Group image Base64 length: ${imageData.length} bytes');
      }

      await groupRef.update({
        'groupImage': imageData,
      });
      print('Group image updated successfully');
    } catch (e) {
      print('Error updating group image: $e');
      throw Exception('Failed to update group image: $e');
    }
  }

  Future<String> getGroupImageBase64(String groupId) async {
    try {
      final doc = await _firestore.collection('Groups').doc(groupId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['groupImage'] ?? '';
      }
      return '';
    } catch (e) {
      print('Error getting group image: $e');
      return '';
    }
  }

  Future<Map<String, Contact>> fetchGroupMemberProfiles({
    required List<String> memberIds,
    required String currentUserId,
  }) async {
    final Map<String, Contact> result = {};
    dynamic currentUserData;

    for (final userId in memberIds) {
      if (userId == currentUserId) {
        currentUserData = await _authService.getUserProfile();
        final profileImageBase64 = await _authService.getImageBase64(userId);
        final profileImage = Base64toImage.convert(profileImageBase64);
        result[userId] = Contact(
          'self_$userId',
          userId,
          currentUserData['username'],
          'Me',
          profileImage,
        );
        continue;
      };

      try {
        try {
          final contactDetails = await _contactService.getContactDetails(
            currentUserId,
            userId,
          );
          final profileImageBase64 =
          await _authService.getImageBase64(contactDetails['id']);
          final profileImage = Base64toImage.convert(profileImageBase64);

          result[userId] = Contact(
            contactDetails['id'],
            contactDetails['userId'],
            contactDetails['username'],
            contactDetails['alias'],
            profileImage,
          );
          continue;
        } catch (_) {

        }

        // Unknown contact
        final username = await _instance.getUsernameByUserId(userId);
        result[userId] = Contact(
          'unknown_$userId',
          userId,
          username,
          'Not In Contacts',
          Uint8List(0),
        );
      } catch (e) {
        print('Error loading profile for $userId: $e');
      }
    }

    return result;
  }
}
