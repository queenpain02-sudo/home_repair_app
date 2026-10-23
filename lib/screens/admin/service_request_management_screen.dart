import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class ServiceRequestManagementScreen extends StatelessWidget {
  ServiceRequestManagementScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'rejected':
        return 'Rejected';
      case 'accepted':
        return 'Accepted';
      case 'on_the_way':
        return 'On The Way';
      case 'arrived':
        return 'Arrived';
      case 'inspection':
        return 'Inspection';
      case 'quotation':
        return 'Quotation';
      case 'customer_approved':
        return 'Customer Approved';
      case 'customer_rejected':
        return 'Customer Rejected';
      case 'repairing':
        return 'Repairing';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'payment_pending':
        return 'Payment Pending';
      case 'payment_paid':
        return 'Payment Paid';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'accepted':
        return Colors.indigo;
      case 'on_the_way':
        return Colors.deepPurple;
      case 'arrived':
        return Colors.teal;
      case 'inspection':
        return Colors.amber.shade800;
      case 'quotation':
        return Colors.purple;
      case 'customer_approved':
        return Colors.green;
      case 'customer_rejected':
        return Colors.redAccent;
      case 'repairing':
        return Colors.cyan.shade800;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.grey;
      case 'payment_pending':
        return Colors.orange;
      case 'payment_paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // SHOW TECHNICIAN ASSIGN DIALOG
  // ============================================================
  Future<void> _showAssignTechnicianDialog(
    BuildContext context,
    String requestId,
  ) async {
    print('===== OPEN DIALOG TRIGGERED FOR REQUEST: $requestId =====');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Assign Technician'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('===== FIRESTORE ERROR: ${snapshot.error} =====');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                print('===== TOTAL USERS FOUND: ${allDocs.length} =====');

                final techDocs = allDocs.where((doc) {
                  final data = doc.data();
                  final role = data['role']?.toString().toLowerCase() ?? '';
                  print('User Email: ${data['email']} | Role: $role');
                  return role == 'technician';
                }).toList();

                print('===== FILTERED TECHNICIANS COUNT: ${techDocs.length} =====');

                if (techDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No technicians found.\n(role = "technician" ရှိသူ မရှိပါ။)',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: techDocs.length,
                  itemBuilder: (context, index) {
                    final techDoc = techDocs[index];
                    final techData = techDoc.data();
                    final techId = techDoc.id;
                    final techName = techData['name']?.toString() ??
                        techData['fullName']?.toString() ??
                        'Technician';
                    final techPhone = techData['phone']?.toString() ??
                        techData['phoneNumber']?.toString() ??
                        '';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          techName.isNotEmpty ? techName[0].toUpperCase() : 'T',
                        ),
                      ),
                      title: Text(techName),
                      subtitle: Text(techPhone),
                      onTap: () async {
                        try {
                          await _firestore
                              .collection('service_requests')
                              .doc(requestId)
                              .update({
                            'technicianId': techId,
                            'technicianName': techName,
                            'status': 'assigned',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Assigned to $techName successfully.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to assign: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('service_requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading requests:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _firestore.collection('service_requests').limit(1).get();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return _requestCard(context, docs[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final serviceName = data['serviceName']?.toString() ?? 'Repair Service';
    final categoryName = data['categoryName']?.toString() ?? '';
    final customerName =
        data['customerName']?.toString() ??
        data['name']?.toString() ??
        'Customer';
    final customerPhone = data['phone']?.toString() ?? '';
    final technicianName = data['technicianName']?.toString() ?? '';
    final address = data['address']?.toString() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final quotationAmount = _toDouble(data['quotationAmount']);
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.home_repair_service,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (categoryName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            categoryName,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
                _statusChip(_statusLabel(status), color),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            _infoRow(Icons.person_outline, customerName),
            if (customerPhone.isNotEmpty)
              _infoRow(Icons.phone_outlined, customerPhone),
            if (address.isNotEmpty)
              _infoRow(Icons.location_on_outlined, address),

            const SizedBox(height: 10),

            // 🛠️ နှိပ်ရလွယ်ကူသော Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: technicianName.isNotEmpty
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  foregroundColor: technicianName.isNotEmpty
                      ? Colors.green.shade800
                      : Colors.blue.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  print('===== ASSIGN BUTTON CLICKED FOR ID: ${doc.id} =====');
                  _showAssignTechnicianDialog(context, doc.id);
                },
                icon: const Icon(Icons.engineering),
                label: Text(
                  technicianName.isNotEmpty
                      ? 'Technician: $technicianName (Change)'
                      : 'Assign Technician',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (quotationAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _infoRow(
                  Icons.receipt_long,
                  'Quotation: ${_formatAmount(quotationAmount)} Ks',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'No Service Requests',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Customer request မရှိသေးပါ။',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}