import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String groupName;
  final String createdBy;
  final DateTime? createdAt;
  final List<String> members;
  final List<String> admins;
  final String? groupImage;

  Group({
    required this.id,
    required this.groupName,
    required this.createdBy,
    required this.members,
    required this.admins,
    this.createdAt,
    this.groupImage,
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
      groupImage: data['groupImage'] ?? '',
    );
  }

  Map<String, dynamic> toDoc() {
    return {
      'groupName': groupName,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'members': members,
      'admins': admins,
      'groupImage': groupImage ?? '',
    };
  }
}