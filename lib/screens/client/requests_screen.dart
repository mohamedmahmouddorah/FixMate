import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  void _showCompleteDialog(BuildContext context, RepairRequest req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Repair'),
        content: const Text('Are you sure you have finished this repair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              AppController.instance.completeRequest(req.id);
              Navigator.pop(context);
            },
            child: const Text('Yes, Finished'),
          ),
        ],
      ),
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
            child: TextFormField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes / Time Estimate'),
              maxLines: 2,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  AppController.instance.acceptRequest(req.id, notesController.text.trim());
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
    final auth = AuthService.instance;
    final isClient = !auth.isAdmin && !auth.isTechnician;
    final isTech = auth.isTechnician;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Requests Status')),
      body: AnimatedBuilder(
        animation: AppController.instance,
        builder: (context, _) {
          final all = AppController.instance.requests;
          List<RepairRequest> displayList = [];

          if (isClient) {
            displayList = all.where((r) => r.clientEmail == auth.currentUserEmail).toList();
          } else if (isTech) {
            // Engineer sees: pending requests + requests they are working on (including completed ones)
            displayList = all.where((r) => r.status == 'pending' || r.techEmail == auth.currentUserEmail).toList();
          } else if (isAdmin) {
            // Admin sees everything (especially completed ones)
            displayList = all.toList();
          }

          if (displayList.isEmpty) {
            return const Center(child: Text('No requests found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final req = displayList[index];
              final isDone = req.status == 'completed';
              final isAccepted = req.status == 'accepted';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(req.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(color: _getStatusColor(req.status), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(req.description, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(req.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      if (req.techNotes != null) ...[
                        const Divider(height: 24),
                        Text('Tech Notes: ${req.techNotes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 16),
                      // Actions
                      if (isTech && !isDone) ...[
                        if (req.status == 'pending')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showAcceptDialog(context, req),
                              child: const Text('Accept & Fix'),
                            ),
                          )
                        else if (isAccepted && req.techEmail == auth.currentUserEmail)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showCompleteDialog(context, req),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Mark as Completed'),
                            ),
                          ),
                      ],
                      if (isAdmin && isDone)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('✅ Verified by System', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'accepted': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
