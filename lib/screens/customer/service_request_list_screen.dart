import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServiceRequestListScreen extends StatelessWidget {
  const ServiceRequestListScreen({super.key});

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';

      case 'assigned':
        return 'Technician Assigned';

      case 'accepted':
        return 'Accepted';

      case 'on_the_way':
        return 'Technician On The Way';

      case 'arrived':
        return 'Technician Arrived';

      case 'inspection':
        return 'Inspection';

      case 'quotation':
        return 'Quotation Received';

      case 'customer_approved':
        return 'Approved';

      case 'customer_rejected':
        return 'Quotation Rejected';

      case 'repairing':
        return 'Repairing';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'assigned':
      case 'accepted':
        return Colors.blue;

      case 'on_the_way':
      case 'arrived':
        return Colors.deepOrange;

      case 'inspection':
        return Colors.indigo;

      case 'quotation':
        return Colors.purple;

      case 'customer_approved':
        return Colors.green;

      case 'customer_rejected':
      case 'cancelled':
        return Colors.red;

      case 'repairing':
        return Colors.teal;

      case 'completed':
        return Colors.green;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Service Requests')),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .where('customerId', isEqualTo: user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load service requests.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 70),
                    SizedBox(height: 16),
                    Text(
                      'No Service Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your service requests will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final serviceName = data['serviceName']?.toString() ?? 'Service';

              final categoryName = data['categoryName']?.toString() ?? '';

              final status = data['status']?.toString() ?? 'pending';

              final address = data['address']?.toString() ?? '';

              final quotationAmount = data['quotationAmount'] is num
                  ? (data['quotationAmount'] as num).toDouble()
                  : double.tryParse(data['quotationAmount']?.toString() ?? '');

              final statusColor = _statusColor(context, status);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.push(
                      '/customer/service-request-detail',
                      extra: {'requestId': doc.id},
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                serviceName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (categoryName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            categoryName,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (address.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(address)),
                            ],
                          ),

                        if (quotationAmount != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Quotation: '
                                '${quotationAmount.toStringAsFixed(0)} MMK',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),

                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'View Details →',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
