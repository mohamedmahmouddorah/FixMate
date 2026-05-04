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
  void _editProfile(BuildContext context, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  AppController.instance.authService.updateUser(
                    email: AppController.instance.authService.currentUserEmail!,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
          ],
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
              authService.currentUserPhone ?? ''
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
            const SizedBox(height: 16),
            _buildInfoCard(context, 'Email', authService.currentUserEmail ?? 'N/A', Icons.email_outlined),
            const SizedBox(height: 16),
            _buildInfoCard(context, 'Phone', authService.currentUserPhone ?? 'N/A', Icons.phone_outlined),
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
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
