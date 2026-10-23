import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const ServiceRequestDetailScreen({super.key, required this.requestId});

  @override
  State<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends State<ServiceRequestDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isAssigning = false;

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
        return Colors.deepOrange;
      case 'payment_paid':
        return Colors.green.shade800;
      default:
        return Colors.grey;
    }
  }

  Future<void> _assignTechnician(Map<String, dynamic> requestData) async {
    if (_isAssigning) return;

    final technician = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _TechnicianSelectionDialog(),
    );

    if (technician == null) return;

    setState(() {
      _isAssigning = true;
    });

    try {
      final technicianId = technician['id']?.toString() ?? '';
      final technicianName = technician['name']?.toString() ?? 'Technician';

      if (technicianId.isEmpty) {
        throw Exception('Technician ID မတွေ့ပါ။');
      }

      await _firestore
          .collection('service_requests')
          .doc(widget.requestId)
          .update({
            'technicianId': technicianId,
            'technicianName': technicianName,
            'status': 'assigned',
            'assignedAt': FieldValue.serverTimestamp(),
            'assignedBy': 'admin',
            'rejectionReason': FieldValue.delete(),
            'rejectedBy': FieldValue.delete(),
            'rejectedTechnicianId': FieldValue.delete(),
            'rejectedAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('request_status_history').add({
        'requestId': widget.requestId,
        'status': 'assigned',
        'changedBy': 'admin',
        'technicianId': technicianId,
        'technicianName': technicianName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔔 Customer Notification (requestId, serviceRequestId အစုံအလင်ဖြင့်)
      final customerId = requestData['customerId']?.toString() ?? '';

      if (customerId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': customerId,
          'requestId': widget.requestId,
          'serviceRequestId': widget.requestId,
          'type': 'technician_assigned',
          'notificationType': 'technician_assigned',
          'title': 'Technician Assigned',
          'message':
              '$technicianName has been assigned to your service request.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _showMessage('Technician assigned successfully.');
    } catch (e) {
      _showMessage('Technician assignment failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  Future<void> _unassignTechnician(Map<String, dynamic> requestData) async {
    final technicianName = requestData['technicianName']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Technician?'),
          content: Text(
            technicianName.isEmpty
                ? 'Assigned technician ကို ဖယ်မလား?'
                : '$technicianName ကို ဖယ်မလား?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _firestore
          .collection('service_requests')
          .doc(widget.requestId)
          .update({
            'technicianId': FieldValue.delete(),
            'technicianName': FieldValue.delete(),
            'status': 'pending',
            'assignedAt': FieldValue.delete(),
            'assignedBy': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('request_status_history').add({
        'requestId': widget.requestId,
        'status': 'pending',
        'changedBy': 'admin',
        'reason': 'Technician assignment removed.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Technician removed.');
    } catch (e) {
      _showMessage('Remove failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Request Detail')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('service_requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Service request not found.'));
          }

          final data = snapshot.data!.data() ?? {};
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final technicianId = data['technicianId']?.toString() ?? '';
    final technicianName = data['technicianName']?.toString() ?? '';
    final quotationAmount = _toDouble(data['quotationAmount']);
    final paymentAmount = _toDouble(data['paymentAmount']) > 0
        ? _toDouble(data['paymentAmount'])
        : (quotationAmount > 0 ? quotationAmount : _toDouble(data['price']));
    final paymentStatus = data['paymentStatus']?.toString() ?? 'unpaid';
    final invoiceId = data['invoiceId']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statusCard(status),
        const SizedBox(height: 16),
        _section(
          title: 'Service Information',
          icon: Icons.home_repair_service_outlined,
          children: [
            _info('Service', data['serviceName']),
            _info('Category', data['categoryName']),
            _info(
              'Base Price',
              '${_formatAmount(_toDouble(data['price']))} Ks',
            ),
            if (quotationAmount > 0)
              _info('Quotation Amount', '${_formatAmount(quotationAmount)} Ks'),
            _info(
              'Description',
              data['customerDescription'] ?? data['description'],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Customer Information',
          icon: Icons.person_outline,
          children: [
            _info('Name', data['customerName'] ?? data['name']),
            _info('Email', data['customerEmail'] ?? data['email']),
            _info('Phone', data['phone']),
            _info('Address', data['address']),
            _info('Township', data['township']),
            _info('City', data['city']),
            _info('Address Note', data['addressNote']),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Request Information',
          icon: Icons.assignment_outlined,
          children: [
            _info('Preferred Date', data['preferredDate']),
            _info('Preferred Time', data['preferredTime']),
            _info('Payment Status', paymentStatus),
            _info('Payment Amount', '${_formatAmount(paymentAmount)} Ks'),
            _info('Payment Method', data['paymentMethod']),
            _info('Transaction ID', data['transactionId']),
            _info('Payment ID', data['paymentId']),
          ],
        ),
        const SizedBox(height: 16),
        if (quotationAmount > 0) ...[
          _section(
            title: 'Quotation Details',
            icon: Icons.receipt_long_outlined,
            children: [
              _info('Quotation ID', data['quotationId']),
              _info('Quotation Amount', '${_formatAmount(quotationAmount)} Ks'),
              _info('Quotation Status', data['quotationStatus']),
              _info('Inspection Note', data['inspectionNote']),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _paymentStatusCard(data, status, paymentStatus, invoiceId),
        const SizedBox(height: 16),
        _technicianSection(data, technicianId, technicianName, status),
        const SizedBox(height: 16),
        _buildTimelineSection(),
        const SizedBox(height: 16),
        if (invoiceId.isNotEmpty) ...[
          _section(
            title: 'Invoice Details',
            icon: Icons.description_outlined,
            children: [
              _info('Invoice ID', invoiceId),
              _info('Invoice Status', data['invoiceStatus']),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _section(
          title: 'System Information',
          icon: Icons.tag_outlined,
          children: [_info('Request ID', widget.requestId)],
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Status Timeline History',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('request_status_history')
                  .where('requestId', isEqualTo: widget.requestId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final historyDocs = snapshot.data!.docs;
                if (historyDocs.isEmpty) {
                  return const Text('No timeline history recorded.');
                }

                historyDocs.sort((a, b) {
                  final aTime = a.data()['createdAt'] as Timestamp?;
                  final bTime = b.data()['createdAt'] as Timestamp?;
                  return (aTime?.millisecondsSinceEpoch ?? 0).compareTo(
                    bTime?.millisecondsSinceEpoch ?? 0,
                  );
                });

                return Column(
                  children: historyDocs.map((doc) {
                    final hData = doc.data();
                    final status = hData['status']?.toString() ?? '';
                    final changedBy = hData['changedBy']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_statusLabel(status)} (by $changedBy)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentStatusCard(
    Map<String, dynamic> data,
    String status,
    String paymentStatus,
    String invoiceId,
  ) {
    if (paymentStatus == 'paid') {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Payment Confirmed',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                status == 'completed'
                    ? 'Payment confirmed and repair completed.'
                    : 'Payment confirmed. Technician can continue the repair.',
              ),
            ],
          ),
        ),
      );
    }

    if (paymentStatus == 'pending') {
      return _messageCard(
        icon: Icons.pending_actions_outlined,
        color: Colors.deepOrange,
        title: 'Payment Pending',
        message: 'Customer payment is waiting for admin verification.',
      );
    }

    if (paymentStatus == 'rejected') {
      return _messageCard(
        icon: Icons.cancel_outlined,
        color: Colors.red,
        title: 'Payment Rejected',
        message:
            data['paymentRejectionReason']?.toString() ??
            'Payment was rejected.',
      );
    }

    return _messageCard(
      icon: Icons.payment_outlined,
      color: Colors.orange,
      title: 'Payment Not Completed',
      message: 'Customer has not completed payment yet.',
    );
  }

  Widget _messageCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _technicianSection(
    Map<String, dynamic> data,
    String technicianId,
    String technicianName,
    String status,
  ) {
    final hasTechnician = technicianId.isNotEmpty;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.engineering_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Technician Assignment',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isAssigning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            if (hasTechnician) ...[
              _info('Technician', technicianName),
              _info('Technician ID', technicianId),
              if (status == 'rejected') ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data['rejectionReason']?.toString() ??
                            'No reason provided.',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAssigning
                          ? null
                          : () => _assignTechnician(data),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Change'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAssigning
                          ? null
                          : () => _unassignTechnician(data),
                      icon: const Icon(Icons.person_remove),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'No technician assigned.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isAssigning
                      ? null
                      : () => _assignTechnician(data),
                  icon: const Icon(Icons.person_add),
                  label: const Text('ASSIGN TECHNICIAN'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TechnicianSelectionDialog extends StatefulWidget {
  const _TechnicianSelectionDialog();

  @override
  State<_TechnicianSelectionDialog> createState() =>
      _TechnicianSelectionDialogState();
}

class _TechnicianSelectionDialogState
    extends State<_TechnicianSelectionDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _search = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Technician'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search technician...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('technicians')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filtered = docs.where((doc) {
                    final data = doc.data();
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final phone = data['phone']?.toString().toLowerCase() ?? '';
                    final email = data['email']?.toString().toLowerCase() ?? '';

                    return name.contains(_search) ||
                        phone.contains(_search) ||
                        email.contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No active technicians found.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();

                      final name =
                          data['name']?.toString().trim() ?? 'Technician';
                      final phone = data['phone']?.toString().trim() ?? '';
                      final specialization =
                          data['specialization']?.toString().trim() ?? '';

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.engineering),
                          ),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (phone.isNotEmpty) Text(phone),
                              if (specialization.isNotEmpty)
                                Text(specialization),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context, {
                              'id': doc.id,
                              'name': name,
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
