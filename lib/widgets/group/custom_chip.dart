import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  final String label;
  final bool isAdmin;
  final VoidCallback? onToggleAdmin;
  final VoidCallback? onRemove;
  final bool isUnknown;
  final bool isCreatorInCreateMode;

  const CustomChip({
    Key? key,
    required this.label,
    required this.isAdmin,
    this.onToggleAdmin,
    this.onRemove,
    this.isUnknown = false,
    this.isCreatorInCreateMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCreatorInCreateMode ? Colors.grey[200] : Colors.grey[100],
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
                message:
                    isCreatorInCreateMode
                        ? 'Group creator (Admin required)'
                        : (isAdmin ? 'Remove Admin' : 'Make Admin'),
                child: GestureDetector(
                  onTap: isCreatorInCreateMode ? null : onToggleAdmin,
                  child: Icon(
                    isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.admin_panel_settings_outlined,
                    size: 18,
                    color:
                        isCreatorInCreateMode
                            ? Color(0xFFF4A44A)
                            : (isAdmin ? Color(0xFFF4A44A) : Colors.grey[600]),
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
}
