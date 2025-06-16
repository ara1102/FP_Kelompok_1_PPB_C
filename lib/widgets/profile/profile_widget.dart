import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/profile/profile_image_form.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/profile/profile_logout.dart';
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      return const Center(child: Text('Tidak ada pengguna yang login.'));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AuthService.instance.getProfile(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final userData = snapshot.data?.data();
            if (userData == null) {
              return const Center(
                child: Text('Data pengguna tidak ditemukan.'),
              );
            }

            final username = userData['username'] ?? 'No username';
            final email = currentUser.email ?? 'No email';
            final image = Base64toImage.convert(userData['image'] ?? '');

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 12),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipOval(
                        child: Image.memory(
                          image,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[50],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.deepPurple,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: ProfileImageForm(image: image),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Expanded(child: ListView(children: [ProfileLogout()])),
              ],
            );
          },
        ),
      ),
    );
  }
}
