import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/app_controller.dart';
import '../auth/login_screen.dart';
import '../admin/dashboard_screen.dart';
import '../admin/manage_devices_screen.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editProfile(BuildContext context, String currentName, String currentPhone, String currentBio) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final bioController = TextEditingController(text: currentBio);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      label: 'Name',
                      controller: nameController,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Phone',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length != 11) return 'Must be exactly 11 digits';
                        if (!RegExp(r"^\d+$").hasMatch(v)) return 'Numbers only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Bio / Description',
                      controller: bioController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              AppController.instance.authService.updateProfile(
                                email: AppController.instance.authService.currentUserEmail!,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                bio: bioController.text.trim(),
                              );
                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _changePassword(BuildContext context) {
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'New Password',
                  controller: passController,
                  isPassword: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: confirmPassController,
                  isPassword: true,
                  validator: (v) => v != passController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          AppController.instance.authService.changePassword(passController.text);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully')),
                          );
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteMyAccount(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final authService = AppController.instance.authService;
                authService.deleteUser(email);
                authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AppController.instance.authService;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProfile(
              context, 
              authService.currentUserName ?? '', 
              authService.currentUserPhone ?? '',
              authService.currentUserBio ?? ''
            ),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(
                authService.currentUserRole?.toUpperCase() ?? 'CLIENT',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            _buildInfoCard(context, 'Name', authService.currentUserName ?? 'N/A', Icons.person_outline),
            const SizedBox(height: 12),
            _buildInfoCard(context, 'Email', authService.currentUserEmail ?? 'N/A', Icons.email_outlined),
            const SizedBox(height: 12),
            _buildInfoCard(context, 'Phone', authService.currentUserPhone ?? 'N/A', Icons.phone_outlined),
            const SizedBox(height: 12),
            _buildInfoCard(context, 'User ID', authService.currentUserId ?? 'N/A', Icons.badge_outlined),
            if (authService.currentUserBio != null && authService.currentUserBio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(context, 'Bio', authService.currentUserBio!, Icons.info_outline),
            ],
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () => _changePassword(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Change Password'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Show Admin Action Buttons
            if (authService.isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Manage Users (Admin)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManageDevicesScreen()),
                  );
                },
                icon: const Icon(Icons.devices_other),
                label: const Text('Manage Devices (Admin)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                if (authService.currentUserEmail != null) {
                  _deleteMyAccount(context, authService.currentUserEmail!);
                }
              },
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Delete My Account', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
