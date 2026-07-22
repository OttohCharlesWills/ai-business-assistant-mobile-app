import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../widgets/app_loader.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;

  Map<String, dynamic>? admin;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() => loading = true);

    try {
      final response = await ProfileService.getProfile();

      if (response['status'] == true) {
        admin = response['admin'];
      } else {
        admin = null;
      }
    } catch (e) {
      admin = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2847),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2F5DA8).withOpacity(.20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8FAADC),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8FAADC),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0C1F3F),

      appBar: AppBar(

        backgroundColor: const Color(0xFF0C1F3F),

        elevation: 0,

        centerTitle: true,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(

            icon: const Icon(Icons.refresh_rounded),

            onPressed: fetchProfile,

          ),

        ],

      ),

      body: loading

          ? const FullScreenLoader(
              message: "Loading profile...",
            )

          : admin == null

              ? const Center(
                  child: Text(
                    "Unable to load profile",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                )

              : RefreshIndicator(

                  onRefresh: fetchProfile,

                  color: const Color(0xFF2F5DA8),

                  backgroundColor: const Color(0xFF0F2847),

                  child: ListView(

                    padding: const EdgeInsets.all(20),

                    children: [

                      const SizedBox(height: 10),

                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              const Color(0xFF2F5DA8),
                          child: Text(
                            admin!['name']
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          admin!['name'] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Center(
                        child: Text(
                          admin!['email'] ?? "",
                          style: const TextStyle(
                            color: Color(0xFF8FAADC),
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      infoTile(
                        icon: Icons.person,
                        title: "Full Name",
                        value: admin!['name'] ?? "",
                      ),

                      infoTile(
                        icon: Icons.email_outlined,
                        title: "Email Address",
                        value: admin!['email'] ?? "",
                      ),

                      const SizedBox(height: 30),
                        SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F5DA8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  name: admin!['name'] ?? '',
                                  email: admin!['email'] ?? '',
                                ),
                              ),
                            );

                            if (updated == true) {
                              fetchProfile();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2847),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF8FAADC),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your account information is securely stored and protected.",
                                style: TextStyle(
                                  color: Color(0xFF8FAADC),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}