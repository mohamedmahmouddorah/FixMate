import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../models/request_model.dart';
import '../../theme/app_theme.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  void _showEditRequestDialog(BuildContext context, RepairRequest req) {
    final deviceController = TextEditingController(text: req.device);
    final descController = TextEditingController(text: req.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Request'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: deviceController,
                  decoration: const InputDecoration(labelText: 'Device Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Problem Description'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
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
                  AppController.instance.updateRequest(
                    req.id,
                    device: deviceController.text.trim(),
                    description: descController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAcceptDialog(BuildContext context, RepairRequest req) {
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Accept Request'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Time Estimate',
                    hintText: 'e.g. I can fix this in 2 days...',
                  ),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  AppController.instance.acceptRequest(
                    req.id, 
                    notesController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, _) {
        final isTechnician = AppController.instance.isTechnician;
        final requests = isTechnician
            ? AppController.instance.allRequests
            : AppController.instance.myRequests;

        return Scaffold(
          appBar: AppBar(
            title: Text(isTechnician ? 'All Requests (Tech)' : 'My Requests'),
          ),
          body: requests.isEmpty
              ? _buildEmptyState(isTechnician)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final color = AppTheme.getStatusColor(req.status);
                    final icon = AppTheme.getStatusIcon(req.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.devices, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              req.device,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                req.category.toUpperCase(),
                                                style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(icon, size: 14, color: color),
                                      const SizedBox(width: 4),
                                      Text(
                                        req.status.toUpperCase(),
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              req.description,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    req.location,
                                    style: const TextStyle(color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (req.imagePath != null && req.imagePath!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(req.imagePath!),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            if (req.techNotes != null && req.techNotes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.verified, size: 16, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text('Technician Notes:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(req.techNotes!, style: const TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ],
                            if (isTechnician) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    req.clientEmail,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                            // Actions for Technician Mode
                            if (isTechnician && req.status != 'completed' && req.status != 'rejected') ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (req.status == 'pending')
                                    ElevatedButton(
                                      onPressed: () => _showAcceptDialog(context, req),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.acceptedColor),
                                      child: const Text('Accept'),
                                    ),
                                  if (req.status == 'accepted')
                                    ElevatedButton(
                                      onPressed: () => AppController.instance.completeRequest(req.id),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.doneColor),
                                      child: const Text('Mark Done'),
                                    ),
                                ],
                              )
                            ],
                            // Actions for Client Mode
                            if (!isTechnician && req.status == 'pending') ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _showEditRequestDialog(context, req),
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Edit Request',
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      AppController.instance.deleteRequest(req.id);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isTechnician) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            isTechnician ? 'No requests available' : 'You have no requests',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
