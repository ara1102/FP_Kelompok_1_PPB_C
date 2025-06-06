import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String groupName;
  final String createdBy;
  final DateTime? createdAt;
  final List<String> members;
  final List<String> admins;

  Group({
    required this.id,
    required this.groupName,
    required this.createdBy,
    required this.members,
    required this.admins,
    this.createdAt,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Group(
      id: doc.id,
      groupName: data['groupName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      members: List<String>.from(data['members'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
    );
  }

  Map<String, dynamic> toDoc() {
    return {
      'groupName': groupName,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'members': members,
      'admins': admins,
    };
  }
}

class GroupService {
  static final GroupService _instance = GroupService();
  static GroupService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;

  // Create Group
  Future<String> createGroup({
    required String groupName,
    required String creatorId,
    required List<String> contactUserIds,
  }) async {
    final allMembers = [...contactUserIds, creatorId];
    final allAdmins = [creatorId];

    final groupData = {
      'groupName': groupName,
      'createdBy': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
      'members': allMembers,
      'admins': allAdmins,
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

}
