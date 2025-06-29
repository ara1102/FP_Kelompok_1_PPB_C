import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';

class ProfileLogout extends StatelessWidget {
  const ProfileLogout({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Logout'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'No',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    overlayColor: const Color(0xFFF4A44A),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // Tutup dialog dulu
                    await AuthService.instance.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('login');
                    }
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFF4A44A)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
