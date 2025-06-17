import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/group_image_form.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/group/custom_chip.dart';
import 'package:fp_kelompok_1_ppb_c/models/contact.dart';

class GroupDialog extends StatefulWidget {
  final String? initialGroupId;
  final String? initialGroupImage;
  final String? initialGroupName;
  final List<String>? initialMembers;
  final List<String>? initialAdmins;
  final String currentUserId;
  final void Function(
    String groupName,
    List<String> members,
    List<String> admins,
  )?
  onSubmit;

  const GroupDialog({
    Key? key,
    this.initialGroupId,
    this.initialGroupImage,
    this.initialGroupName,
    this.initialMembers,
    this.initialAdmins,
    required this.currentUserId,
    this.onSubmit,
  }) : super(key: key);

  @override
  _GroupDialogState createState() => _GroupDialogState();
}

class _GroupDialogState extends State<GroupDialog> {
  late TextEditingController _groupNameController;
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _selectedMemberIds = {};
  Set<String> _selectedAdminIds = {};
  String _searchText = '';
  bool _loading = true;
  Uint8List? groupImage;
  Uint8List? profileImage;
  bool _isSearchFocused = false;

  final Map<String, String> _unknownUsernames = {};
  final FocusNode _searchFocusNode = FocusNode();
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  final ContactService _contactService = ContactService();

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(
      text: widget.initialGroupName ?? '',
    );
    _selectedMemberIds = Set.from(widget.initialMembers ?? []);
    _selectedAdminIds = Set.from(widget.initialAdmins ?? []);

    if (_selectedAdminIds.isEmpty) {
      _selectedAdminIds.add(widget.currentUserId);
    }

    _loadContacts(widget.currentUserId);

    if (widget.initialGroupImage != null &&
        widget.initialGroupImage!.isNotEmpty) {
      groupImage = Base64toImage.convert(widget.initialGroupImage!);
    } else {
      groupImage = Uint8List(0);
    }

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts(String userId) async {
    setState(() => _loading = true);

    try {
      final snapshot = await _contactService.getAllContacts(userId).first;

      final Map<String, Contact> contactsMap = {};

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        for (final contactUserId in data.keys) {
          try {
            final contactDetails = await _contactService.getContactDetails(
              userId,
              contactUserId,
            );
            final profileImageBase64 = await _authService.getImageBase64(
              contactUserId,
            );
            final profileImage = Base64toImage.convert(profileImageBase64);

            contactsMap[contactUserId] = Contact(
              contactDetails['id'],
              contactDetails['userId'],
              contactDetails['username'],
              contactDetails['alias'],
              profileImage,
            );
          } catch (e) {
            print('Failed to load contact $contactUserId: $e');
          }
        }
      }

      final memberProfiles = await _groupService.fetchGroupMemberProfiles(
        memberIds: widget.initialMembers ?? [],
        currentUserId: widget.currentUserId,
      );

      for (final entry in memberProfiles.entries) {
        if (!contactsMap.containsKey(entry.key)) {
          contactsMap[entry.key] = entry.value;
        }
      }

      setState(() {
        _allContacts = contactsMap.values.toList();
        _applyFilter();
      });
    } catch (e) {
      print('Failed to load group member profiles: $e');
      setState(() {
        _allContacts = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (!mounted) return;
    setState(() {
      final lowerSearch = _searchText.toLowerCase();

      _filteredContacts =
          _allContacts.where((c) {
            return c.alias.toLowerCase().contains(lowerSearch) ||
                c.userName.toLowerCase().contains(lowerSearch);
          }).toList();

      _filteredContacts.sort((a, b) => a.alias.compareTo(b.alias));
    });
  }

  void _onSearchChanged(String val) {
    _searchText = val;
    _applyFilter();
  }

  void _toggleMember(Contact contact) {
    setState(() {
      if (_selectedMemberIds.contains(contact.userId)) {
        _selectedMemberIds.remove(contact.userId);
        _selectedAdminIds.remove(contact.userId);
      } else {
        _selectedMemberIds.add(contact.userId);
      }
      _applyFilter();
    });
  }

  void _toggleAdmin(Contact contact) {
    final isCurrentlyAdmin = _selectedAdminIds.contains(contact.userId);

    if (isCurrentlyAdmin) {
      if (_selectedAdminIds.length <= 1) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Admin required'),
                content: Text('You need to choose at least one admin.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
        );
        return;
      } else {
        setState(() {
          _selectedAdminIds.remove(contact.userId);
        });
      }
    } else {
      setState(() {
        _selectedAdminIds.add(contact.userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleContacts =
        _filteredContacts
            .where((c) => !_selectedMemberIds.contains(c.userId))
            .toList();

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keyboardHeight - 200;

    return AlertDialog(
      title: Text(
        widget.initialGroupName == null ? 'Create Group' : 'Edit Group',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: availableHeight.clamp(300.0, 600.0),
        child:
            _loading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Group Picture
                      if (!_isSearchFocused || keyboardHeight == 0)
                        Column(
                          children: [
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipOval(
                                      child: Image.memory(
                                        groupImage ?? Uint8List(0),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFFE4BD),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.group,
                                              size: 60,
                                              color: Color(0xFFF4A44A),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (widget.initialGroupName != null &&
                                        widget.initialGroupId != null)
                                      Positioned(
                                        bottom: -4,
                                        right: -8,
                                        child: Container(
                                          child: GroupImageForm(
                                            image: groupImage!,
                                            groupId: widget.initialGroupId!,
                                            userId: widget.currentUserId,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Group Name Input
                      if (!_isSearchFocused || keyboardHeight == 0)
                        Column(
                          children: [
                            TextField(
                              controller: _groupNameController,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Group Name',
                                hintText: 'Enter a name for your group',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Members section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSearchFocused && keyboardHeight > 0)
                            Text(
                              'Selected Members (${_selectedMemberIds.length})',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Members',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '&',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 18,
                                  color: Color(0xFFF4A44A),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Admin',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 8),

                          // Selected Members Chips
                          Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  (_isSearchFocused && keyboardHeight > 0)
                                      ? 80
                                      : double.infinity,
                            ),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  // Me Chip
                                  CustomChip(
                                    isCreatorInCreateMode:
                                        widget.initialGroupName == null,
                                    label: 'Me',
                                    isAdmin: _selectedAdminIds.contains(
                                      widget.currentUserId,
                                    ),
                                    onToggleAdmin: () {
                                      final currentUserContact = _allContacts
                                          .firstWhere(
                                            (c) =>
                                                c.userId ==
                                                widget.currentUserId,
                                            orElse:
                                                () => Contact(
                                                  'self_${widget.currentUserId}',
                                                  widget.currentUserId,
                                                  'Me',
                                                  'Current User',
                                                  Uint8List(0),
                                                ),
                                          );
                                      _toggleAdmin(currentUserContact);
                                    },
                                    onRemove: null,
                                  ),

                                  // Selected Members Chip
                                  ..._selectedMemberIds
                                      .where((id) => id != widget.currentUserId)
                                      .map((id) {
                                        final contact = _allContacts.firstWhere(
                                          (c) => c.userId == id,
                                          orElse:
                                              () => Contact(
                                                'unknown_$id',
                                                id,
                                                'Unknown User',
                                                'Not In Contacts',
                                                Uint8List(0),
                                              ),
                                        );
                                        return CustomChip(
                                          label:
                                              contact.alias == 'Not In Contacts'
                                                  ? contact.userName
                                                  : contact.alias,
                                          isAdmin: _selectedAdminIds.contains(
                                            id,
                                          ),
                                          onToggleAdmin:
                                              () => _toggleAdmin(contact),
                                          onRemove:
                                              () => _toggleMember(contact),
                                          isUnknown:
                                              contact.alias ==
                                              'Not In Contacts',
                                        );
                                      }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      // Add Members Label
                      Text(
                        'Add Members',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Search Input
                      TextField(
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          suffixIcon:
                              _isSearchFocused
                                  ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      _searchFocusNode.unfocus();
                                      _onSearchChanged('');
                                    },
                                    tooltip: 'Clear search and close keyboard',
                                  )
                                  : null,
                          hintText: 'Search contacts to add',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contact List
                      SizedBox(
                        height:
                            _isSearchFocused && keyboardHeight > 0 ? 250 : 200,
                        child:
                            visibleContacts.isEmpty
                                ? Center(
                                  child: Text(
                                    'No contacts match your search.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  itemCount: visibleContacts.length,
                                  separatorBuilder:
                                      (context, index) => SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final contact = visibleContacts[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(
                                              0.15,
                                            ),
                                            spreadRadius: 1,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                        leading:
                                            (contact.profileImage != null ||
                                                    !contact
                                                        .profileImage!
                                                        .isEmpty)
                                                ? CircleAvatar(
                                                  backgroundImage: MemoryImage(
                                                    contact.profileImage!,
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFFFE4BD,
                                                  ),
                                                  onBackgroundImageError: (
                                                    exception,
                                                    stackTrace,
                                                  ) {
                                                    print(
                                                      'Error loading profile image: $exception',
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Color(0xFFF4A44A),
                                                  ),
                                                )
                                                : CircleAvatar(
                                                  backgroundColor: const Color(
                                                    0xFFFFE4BD,
                                                  ),
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Color(0xFFF4A44A),
                                                  ),
                                                ),
                                        title: Text(
                                          contact.alias,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text(
                                          contact.userName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.person_add_alt_outlined,
                                            color: Colors.black,
                                          ),
                                          onPressed:
                                              () => _toggleMember(contact),
                                          tooltip: 'Add to Group',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(overlayColor: Color(0xFFF4A44A)),
          onPressed: () {
            final groupName = _groupNameController.text.trim();
            if (groupName.isEmpty || _selectedMemberIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Group name and members cannot be empty'),
                ),
              );
              return;
            }
            if (widget.onSubmit != null) {
              widget.onSubmit!(
                groupName,
                _selectedMemberIds.toList(),
                _selectedAdminIds.toList(),
              );
            }
            Navigator.of(context).pop();
          },
          child: Text('Save', style: TextStyle(color: Color(0xFFF4A44A))),
        ),
      ],
    );
  }
}
