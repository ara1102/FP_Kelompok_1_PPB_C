import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/contact_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';

class GroupDialog extends StatefulWidget {
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
    this.initialGroupName,
    this.initialMembers,
    this.initialAdmins,
    required this.currentUserId,
    this.onSubmit,
  }) : super(key: key);

  @override
  _GroupDialogState createState() => _GroupDialogState();
}

class Contact {
  final String contactId;
  final String userId;
  final String userName;
  final String alias;

  Contact(this.contactId, this.userId, this.userName, this.alias);
}

class _GroupDialogState extends State<GroupDialog> {
  late TextEditingController _groupNameController;
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _selectedMemberIds = {};
  Set<String> _selectedAdminIds = {};
  String _searchText = '';
  bool _loading = true;

  final Map<String, String> _unknownUsernames = {};

  final ContactService _contactService = ContactService();
  final GroupService _groupService = GroupService();

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

    _loadContacts(widget.currentUserId).then((_) {
      _loadUnknownUsernames();
    });
  }

  Future<void> _loadUnknownUsernames() async {
    final unknownIds = _selectedMemberIds
        .where((id) => id != widget.currentUserId)
        .where((id) => !_allContacts.any((c) => c.userId == id));

    for (final id in unknownIds) {
      try {
        final username = await _groupService.getUsernameByUserId(id);
        setState(() {
          _unknownUsernames[id] = username;
        });
      } catch (e) {
        print('Failed to get username for $id: $e');
      }
    }
  }

  Widget _buildCustomChip({
    required String label,
    required bool isAdmin,
    VoidCallback? onToggleAdmin,
    VoidCallback? onRemove,
    bool isUnknown = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onToggleAdmin != null ? Colors.grey[200] : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: isAdmin ? 'Remove Admin' : 'Make Admin',
                child: GestureDetector(
                  onTap: onToggleAdmin,
                  child: Icon(
                    isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.admin_panel_settings_outlined,
                    size: 18,
                    color:
                        onToggleAdmin != null
                            ? (isAdmin ? Colors.blue : Colors.black)
                            : Colors.blue,
                  ),
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: isUnknown ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: onRemove != null ? Colors.black54 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadContacts(String userId) async {
    setState(() => _loading = true);
    try {
      final snapshot = await _contactService.getAllContacts(userId).first;
      final contactsData = snapshot.data() as Map<String, dynamic>?;

      if (contactsData == null) {
        setState(() {
          _allContacts = [];
          _applyFilter();
        });
        return;
      }

      final futures = contactsData.entries.map((entry) async {
        final contactUserId = entry.key;
        try {
          final details = await _contactService.getContactDetails(
            widget.currentUserId,
            contactUserId,
          );
          return Contact(
            details['id'],
            details['userId'],
            details['username'], // Use 'username' from details
            details['alias'],
          );
        } catch (e) {
          return null;
        }
      });

      final contacts =
          (await Future.wait(futures)).whereType<Contact>().toList();

      setState(() {
        _allContacts = contacts;
        _applyFilter();
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      final lowerSearch = _searchText.toLowerCase();

      _filteredContacts =
          _allContacts.where((c) {
            return c.alias.toLowerCase().contains(lowerSearch);
          }).toList();

      final filteredUnknowns = _unknownUsernames.entries
          .where(
            (entry) =>
                !_selectedMemberIds.contains(entry.key) &&
                entry.value.toLowerCase().contains(lowerSearch),
          )
          .map(
            (entry) => Contact('-1', entry.key, entry.value, 'Not In Contacts'),
          );

      _filteredContacts.addAll(filteredUnknowns);
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

    return AlertDialog(
      title: Text(
        widget.initialGroupName == null ? 'Create Group' : 'Edit Group',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child:
            _loading
                ? Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Name Input
                    TextField(
                      controller: _groupNameController,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

                    // Section: Current Members & Admins Label Row
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
                          color: Colors.blueAccent,
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCustomChip(
                          label: 'Me',
                          isAdmin: _selectedAdminIds.contains(
                            widget.currentUserId,
                          ),
                          onToggleAdmin:
                              () => _toggleAdmin(
                                Contact(
                                  '0',
                                  widget.currentUserId,
                                  'Me',
                                  'Current User',
                                ),
                              ),
                          onRemove: null,
                        ),
                        ..._selectedMemberIds
                            .where((id) => id != widget.currentUserId)
                            .where(
                              (id) => _allContacts.any((c) => c.userId == id),
                            )
                            .map((id) {
                              final contact = _allContacts.firstWhere(
                                (c) => c.userId == id,
                              );
                              return _buildCustomChip(
                                label: contact.alias,
                                isAdmin: _selectedAdminIds.contains(id),
                                onToggleAdmin: () => _toggleAdmin(contact),
                                onRemove: () => _toggleMember(contact),
                              );
                            }),
                        ..._selectedMemberIds
                            .where((id) => id != widget.currentUserId)
                            .where(
                              (id) => !_allContacts.any((c) => c.userId == id),
                            )
                            .where((id) => _unknownUsernames.containsKey(id))
                            .map((id) {
                              final username = _unknownUsernames[id]!;
                              final unknownMember = Contact(
                                '-1',
                                id,
                                username,
                                'Not In Contacts',
                              );
                              return _buildCustomChip(
                                label: unknownMember.userName,
                                isAdmin: _selectedAdminIds.contains(id),
                                onToggleAdmin:
                                    () => _toggleAdmin(unknownMember),
                                onRemove: () => _toggleMember(unknownMember),
                                isUnknown: true,
                              );
                            }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Add Members Label
                    Text(
                      'Add Members',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Search Input
                    TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search contacts to add',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Contact List or Empty Text
                    Expanded(
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
                                          color: Colors.grey.withOpacity(0.15),
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
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueAccent
                                            .withOpacity(0.1),
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.blueAccent,
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.person_add_alt_outlined,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () => _toggleMember(contact),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
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
          child: Text('Save'),
        ),
      ],
    );
  }
}
