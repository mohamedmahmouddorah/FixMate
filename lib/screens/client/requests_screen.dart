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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
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
    final daysController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Accept Request'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Time Estimate',
                    ),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: daysController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Days for Completion',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: You can only cancel this request within the first 24 hours of acceptance.',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                  AppController.instance.acceptRequest(
                    req.id,
                    notesController.text.trim(),
                    int.parse(daysController.text.trim()),
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
            displayList = all
                .where((r) => r.clientEmail == auth.currentUserEmail)
                .toList();
          } else if (isTech) {
            // Engineer sees: pending requests + requests they are working on (including completed ones)
            displayList = all
                .where(
                  (r) =>
                      r.status == 'pending' ||
                      r.techEmail == auth.currentUserEmail,
                )
                .toList();
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.device,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                req.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(req.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        req.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            req.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (isAdmin) ...[
                        const Divider(height: 24),
                        const Text(
                          'Admin Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: auth.getUserByEmail(req.clientEmail),
                          builder: (context, snapshot) {
                            final clientName = snapshot.data?['name'] ?? 'Loading...';
                            final clientId = snapshot.data?['id'] ?? '...';
                            
                            return Text(
                              'Client: $clientName (ID: $clientId)',
                              style: const TextStyle(fontSize: 13),
                            );
                          },
                        ),
                        if (req.techEmail != null) FutureBuilder<Map<String, dynamic>?>(
                          future: auth.getUserByEmail(req.techEmail!),
                          builder: (context, snapshot) {
                            final techName = snapshot.data?['name'] ?? 'Loading...';
                            final techId = snapshot.data?['id'] ?? '...';
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Technician: $techName (ID: $techId)',
                                style: const TextStyle(fontSize: 13, color: Colors.blue),
                              ),
                            );
                          },
                        ),
                      ],
                      if (req.techNotes != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Tech Notes: ${req.techNotes}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (isAccepted && req.estimatedDays != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Estimated: ${req.estimatedDays} days',
                              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      if (isTech && isAccepted && req.techEmail == auth.currentUserEmail) ...[
                        Builder(builder: (context) {
                          final passed24h = req.acceptedAt != null &&
                              DateTime.now().difference(req.acceptedAt!).inHours >= 24;
                          if (passed24h && !isDone) {
                            return Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cancellation period (24h) ended. You MUST complete this repair.',
                                      style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (req.acceptedAt != null && !passed24h && !isDone) {
                            final timeLeft = 24 - DateTime.now().difference(req.acceptedAt!).inHours;
                            return Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You have $timeLeft hours remaining to cancel this request if needed.',
                                      style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                      const SizedBox(height: 16),
                      // Actions
                      if (isClient) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppController.instance.deleteRequest(req.id);
                            },
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            label: const Text('Delete Request', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                      if (isTech && !isDone) ...[
                        if (req.status == 'pending')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showAcceptDialog(context, req),
                              child: const Text('Accept & Fix'),
                            ),
                          )
                        else if (isAccepted &&
                            req.techEmail == auth.currentUserEmail)
                          Builder(builder: (context) {
                            final canCancel = req.acceptedAt != null &&
                                DateTime.now()
                                        .difference(req.acceptedAt!)
                                        .inHours <
                                    24;
                            return Row(
                              children: [
                                if (canCancel) ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        AppController.instance
                                            .cancelTechRequest(req.id);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side:
                                            const BorderSide(color: Colors.red),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showCompleteDialog(context, req),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Complete'),
                                  ),
                                ),
                              ],
                            );
                          }),
                      ],
                      if (isAdmin && isDone)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '✅ Verified by System',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
