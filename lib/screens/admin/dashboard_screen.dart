import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/custom_text_field.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _refresh() => setState(() {});

  void _showAddEditUserDialog({String? existingEmail}) {
    final authService = AppController.instance.authService;
    final isEditing = existingEmail != null;
    final allUsers = authService.allUsers;

    final nameController = TextEditingController(text: isEditing ? allUsers[existingEmail]!['name'] : '');
    final emailController = TextEditingController(text: isEditing ? existingEmail : '');
    final phoneController = TextEditingController(text: isEditing ? allUsers[existingEmail]!['phone'] : '');
    final idController = TextEditingController(text: isEditing ? allUsers[existingEmail]!['id'] : '');
    final passwordController = TextEditingController();
    
    final defaultRole = allUsers.isEmpty ? 'admin' : 'client';
    String selectedRole = isEditing ? (allUsers[existingEmail]!['role'] ?? 'client') : defaultRole;

    String? formError;
    final bioController = TextEditingController(
      text: isEditing ? (allUsers[existingEmail]!['bio'] ?? '') : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit User' : 'Add New User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (formError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          formError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'client', child: Text('Client')),
                        DropdownMenuItem(value: 'technician', child: Text('Technician')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedRole = val);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Name',
                      controller: nameController,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Email',
                      controller: emailController,
                      enabled: !isEditing,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'National ID (14 digits)',
                      controller: idController,
                      enabled: !isEditing,
                      maxLength: 14,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Phone',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: isEditing ? 'New Password (Optional)' : 'Password',
                      controller: passwordController,
                      isPassword: true,
                    ),
                    if (selectedRole == 'technician') ...[
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Professional Bio / Description',
                        hint: 'e.g. 5 years experience in AC repair...',
                        controller: bioController,
                        prefixIcon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            String n = nameController.text.trim();
                            String e = emailController.text.trim();
                            String id = idController.text.trim();
                            String p = phoneController.text.trim();
                            String pwd = passwordController.text;
                            String bio = bioController.text.trim();

                            if (n.isEmpty) {
                              setStateDialog(() => formError = 'Name is required'); return;
                            }
                            if (!e.contains('@')) {
                              setStateDialog(() => formError = 'Invalid email address'); return;
                            }
                            if (!isEditing && !RegExp(r"^\d{14}$").hasMatch(id)) {
                              setStateDialog(() => formError = 'National ID must be exactly 14 digits'); return;
                            }
                            if (p.length != 11 || !RegExp(r"^\d+$").hasMatch(p)) {
                              setStateDialog(() => formError = 'Phone must be exactly 11 digits'); return;
                            }
                            if (!isEditing && pwd.isEmpty) {
                              setStateDialog(() => formError = 'Password is required'); return;
                            }
                            if (pwd.isNotEmpty && pwd.length < 6) {
                              setStateDialog(() => formError = 'Password must be at least 6 characters'); return;
                            }
                            if (selectedRole == 'technician' && bio.isEmpty) {
                              setStateDialog(() => formError = 'Bio is required for technicians'); return;
                            }

                            setStateDialog(() => formError = null);

                            String? error;
                            if (isEditing) {
                              error = authService.updateUser(
                                email: e,
                                name: n,
                                phone: p,
                                password: pwd,
                                role: selectedRole,
                              );
                            } else {
                              error = authService.addUser(
                                email: e,
                                name: n,
                                phone: p,
                                id: id,
                                password: pwd,
                                role: selectedRole,
                                bio: selectedRole == 'technician' ? bio : null,
                              );
                            }

                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                            } else {
                              Navigator.of(context).pop();
                              _refresh();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'User updated' : 'User added'), backgroundColor: Colors.green));
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteUser(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete $email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final error = AppController.instance.authService.deleteUser(email);
                Navigator.of(context).pop();
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                } else {
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersTable(List<MapEntry<String, Map<String, String>>> users) {
    final authService = AppController.instance.authService;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final entry = users[index];
        final email = entry.key;
        final data = entry.value;
        final isMe = email == authService.currentUserEmail;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (isMe)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('You', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(email)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(data['phone'] ?? 'N/A')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(data['id'] ?? 'N/A')),
                    ],
                  ),
                  if (data.containsKey('bio') && data['bio'] != null && data['bio']!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data['bio']!,
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Role: ${data['role']?.toUpperCase() ?? 'CLIENT'}', 
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddEditUserDialog(existingEmail: email),
                ),
                if (!isMe)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(email),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AppController.instance.authService;
    final allUsers = authService.allUsers;
    
    final clients = allUsers.entries.where((e) => e.value['role'] == 'client' || e.value['role'] == null).toList();
    final technicians = allUsers.entries.where((e) => e.value['role'] == 'technician' || e.value['role'] == 'admin').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Clients'),
              Tab(text: 'Technicians / Admin'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1, size: 28),
              onPressed: () => _showAddEditUserDialog(),
              tooltip: 'Add User',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            _buildUsersTable(clients),
            _buildUsersTable(technicians),
          ],
        ),
      ),
    );
  }
}
