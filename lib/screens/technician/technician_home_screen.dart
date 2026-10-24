import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_repair_app/screens/common/edit_profile_screen.dart';
import 'package:home_repair_app/screens/common/notification_list_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Color primaryColor = const Color(0xFF2563EB);
  final Color backgroundColor = const Color(0xFFF8FAFC);

  String _technicianId = '';
  String _technicianName = 'Technician';
  String _technicianEmail = '';
  String _technicianIdNumber = ''; // 🌟 ID No. အတွက်
  String _technicianProfileImage = ''; // 🌟 ဓာတ်ပုံ URL အတွက်

  bool _loadingTechnician = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadTechnician();
  }

  Future<void> _loadTechnician() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() {
          _loadingTechnician = false;
        });
        return;
      }

      _technicianId = user.uid;
      _technicianEmail = user.email ?? '';

      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (technicianDoc.exists) {
        final data = technicianDoc.data() ?? {};
        _technicianName =
            data['name']?.toString() ??
            data['displayName']?.toString() ??
            user.displayName ??
            'Technician';
        _technicianIdNumber = data['idNumber']?.toString() ?? ''; // 🌟 ID No. ဖတ်ရန်
        _technicianProfileImage = data['profileImage']?.toString() ?? data['profileImageUrl']?.toString() ?? data['imageUrl']?.toString() ?? ''; // 🌟 ဓာတ်ပုံဖတ်ရန်

        setState(() {
          _loadingTechnician = false;
        });
        return;
      }

      if (_technicianEmail.isNotEmpty) {
        final query = await _firestore
            .collection('technicians')
            .where('email', isEqualTo: _technicianEmail)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          _technicianId = query.docs.first.id;
          _technicianName =
              data['name']?.toString() ??
              data['displayName']?.toString() ??
              user.displayName ??
              'Technician';
          _technicianIdNumber = data['idNumber']?.toString() ?? '';
          _technicianProfileImage = data['profileImage']?.toString() ?? data['profileImageUrl']?.toString() ?? data['imageUrl']?.toString() ?? '';

          setState(() {
            _loadingTechnician = false;
          });
          return;
        }
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        _technicianName =
            data['name']?.toString() ??
            data['displayName']?.toString() ??
            user.displayName ??
            'Technician';
        _technicianIdNumber = data['idNumber']?.toString() ?? '';
        _technicianProfileImage = data['profileImage']?.toString() ?? data['profileImageUrl']?.toString() ?? data['imageUrl']?.toString() ?? '';
      }

      setState(() {
        _loadingTechnician = false;
      });
    } catch (e) {
      setState(() {
        _loadingTechnician = false;
      });
      _showMessage('Technician profile load failed: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _acceptJob(String requestId) async {
    try {
      final ref = _firestore.collection('service_requests').doc(requestId);
      final snapshot = await ref.get();

      if (!snapshot.exists) throw Exception('Service request မတွေ့ပါ။');

      final data = snapshot.data() ?? {};
      if (data['technicianId']?.toString() != _technicianId) {
        throw Exception('ဒီအလုပ်က သင့်ထံ assign မလုပ်ထားပါ။');
      }
      if (data['status']?.toString() != 'assigned') {
        throw Exception('ဒီအလုပ်ကို လက်ခံလို့မရတော့ပါ။');
      }

      final batch = _firestore.batch();
      batch.update(ref, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedBy': _technicianId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = _firestore.collection('request_status_history').doc();
      batch.set(historyRef, {
        'requestId': requestId,
        'status': 'accepted',
        'changedBy': 'technician',
        'technicianId': _technicianId,
        'technicianName': _technicianName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _showMessage('Job accepted successfully.');
    } catch (e) {
      _showMessage('Accept failed: $e');
    }
  }

  Future<void> _rejectJob(String requestId) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Reject Job',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter rejection reason...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  reasonController.text.trim().isEmpty
                      ? 'Technician rejected the job.'
                      : reasonController.text.trim(),
                );
              },
              child: const Text('Reject Job'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();
    if (reason == null) return;

    try {
      final ref = _firestore.collection('service_requests').doc(requestId);
      final snapshot = await ref.get();
      if (!snapshot.exists) throw Exception('Service request မတွေ့ပါ။');

      final data = snapshot.data() ?? {};
      if (data['technicianId']?.toString() != _technicianId) {
        throw Exception('ဒီအလုပ်က သင့်ထံ assign မလုပ်ထားပါ။');
      }

      final batch = _firestore.batch();
      batch.update(ref, {
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedBy': 'technician',
        'rejectedTechnicianId': _technicianId,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = _firestore.collection('request_status_history').doc();
      batch.set(historyRef, {
        'requestId': requestId,
        'status': 'rejected',
        'changedBy': 'technician',
        'technicianId': _technicianId,
        'technicianName': _technicianName,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _showMessage('Job rejected.');
    } catch (e) {
      _showMessage('Reject failed: $e');
    }
  }

  Future<void> _updateJobStatus(String requestId, String newStatus) async {
    try {
      final ref = _firestore.collection('service_requests').doc(requestId);
      final snapshot = await ref.get();
      if (!snapshot.exists) throw Exception('Service request မတွေ့ပါ။');

      final data = snapshot.data() ?? {};
      if (data['technicianId']?.toString() != _technicianId) {
        throw Exception('ဒီအလုပ်က သင့်ထံ assign မလုပ်ထားပါ။');
      }

      final allowed = <String, List<String>>{
        'accepted': ['on_the_way'],
        'on_the_way': ['arrived'],
        'arrived': ['inspection'],
        'inspection': ['quotation'],
        'payment_paid': ['repairing'],
      };

      final currentStatus = data['status']?.toString() ?? '';
      if (!(allowed[currentStatus]?.contains(newStatus) ?? false)) {
        throw Exception(
          'Status change မလုပ်နိုင်ပါ။ $currentStatus → $newStatus',
        );
      }

      final batch = _firestore.batch();
      batch.update(ref, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'on_the_way') {
        batch.update(ref, {'onTheWayAt': FieldValue.serverTimestamp()});
      }
      if (newStatus == 'arrived') {
        batch.update(ref, {'arrivedAt': FieldValue.serverTimestamp()});
      }
      if (newStatus == 'inspection') {
        batch.update(ref, {
          'inspectionStartedAt': FieldValue.serverTimestamp(),
        });
      }
      if (newStatus == 'repairing') {
        batch.update(ref, {'repairStartedAt': FieldValue.serverTimestamp()});
      }

      final historyRef = _firestore.collection('request_status_history').doc();
      batch.set(historyRef, {
        'requestId': requestId,
        'status': newStatus,
        'changedBy': 'technician',
        'technicianId': _technicianId,
        'technicianName': _technicianName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _showMessage('Status updated: ${_statusLabel(newStatus)}');
    } catch (e) {
      _showMessage('Status update failed: $e');
    }
  }

  Future<void> _showQuotationDialog(
    String requestId,
    Map<String, dynamic> requestData,
  ) async {
    final inspectionController = TextEditingController();
    final serviceCostController = TextEditingController();
    final partsCostController = TextEditingController();
    final laborCostController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Create Quotation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: inspectionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Inspection Result',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serviceCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Service Cost (Ks)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: partsCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Parts Cost (Ks)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: laborCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Labor Cost (Ks)',
                    border: OutlineInputBorder(),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'inspectionNote': inspectionController.text.trim(),
                  'serviceCost':
                      double.tryParse(serviceCostController.text.trim()) ?? 0,
                  'partsCost':
                      double.tryParse(partsCostController.text.trim()) ?? 0,
                  'laborCost':
                      double.tryParse(laborCostController.text.trim()) ?? 0,
                });
              },
              child: const Text('Send Quotation'),
            ),
          ],
        );
      },
    );

    inspectionController.dispose();
    serviceCostController.dispose();
    partsCostController.dispose();
    laborCostController.dispose();

    if (result == null) return;
    await _submitQuotation(requestId, requestData, result);
  }

  Future<void> _submitQuotation(
    String requestId,
    Map<String, dynamic> requestData,
    Map<String, dynamic> quotation,
  ) async {
    try {
      final serviceCost = _toDouble(quotation['serviceCost']);
      final partsCost = _toDouble(quotation['partsCost']);
      final laborCost = _toDouble(quotation['laborCost']);
      final totalAmount = serviceCost + partsCost + laborCost;

      if (totalAmount <= 0) throw Exception('Quotation amount မမှန်ပါ။');

      final quotationRef = _firestore.collection('quotations').doc();
      final quotationId = quotationRef.id;
      final requestRef = _firestore
          .collection('service_requests')
          .doc(requestId);

      final batch = _firestore.batch();
      batch.set(quotationRef, {
        'quotationId': quotationId,
        'requestId': requestId,
        'customerId': requestData['customerId'],
        'customerName': requestData['customerName'],
        'customerEmail': requestData['customerEmail'],
        'technicianId': _technicianId,
        'technicianName': _technicianName,
        'serviceName': requestData['serviceName'],
        'categoryName': requestData['categoryName'],
        'inspectionNote': quotation['inspectionNote'],
        'serviceCost': serviceCost,
        'partsCost': partsCost,
        'laborCost': laborCost,
        'totalAmount': totalAmount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(requestRef, {
        'status': 'quotation',
        'quotationId': quotationId,
        'quotationAmount': totalAmount,
        'quotationStatus': 'pending',
        'inspectionNote': quotation['inspectionNote'],
        'serviceCost': serviceCost,
        'materialCost': partsCost,
        'laborCost': laborCost,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = _firestore.collection('request_status_history').doc();
      batch.set(historyRef, {
        'requestId': requestId,
        'status': 'quotation',
        'changedBy': 'technician',
        'technicianId': _technicianId,
        'technicianName': _technicianName,
        'quotationId': quotationId,
        'amount': totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final customerId = requestData['customerId']?.toString() ?? '';
      if (customerId.isNotEmpty) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': customerId,
          'requestId': requestId,
          'serviceRequestId': requestId,
          'type': 'quotation_created',
          'notificationType': 'quotation_created',
          'title': 'Quotation Ready',
          'message':
              'Technician has created a quotation for your service request.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _showMessage('Quotation created successfully.');
    } catch (e) {
      _showMessage('Quotation failed: $e');
    }
  }

  Future<void> _completeRepair(
    String requestId,
    Map<String, dynamic> requestData,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Complete Repair',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Repair အလုပ်ပြီးဆုံးပြီလို့ အတည်ပြုပါသလား?\n\n'
            'ပြီးဆုံးပြီးပါက Customer အတွက် Invoice ကို အလိုအလျောက် ဖန်တီးပေးပါမည်။',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete Job'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final requestRef = _firestore
          .collection('service_requests')
          .doc(requestId);
      final snapshot = await requestRef.get();
      if (!snapshot.exists) throw Exception('Service request မတွေ့ပါ။');

      final data = snapshot.data() ?? {};
      final paymentId = data['paymentId']?.toString() ?? '';
      final amount = _toDouble(data['quotationAmount']) > 0
          ? _toDouble(data['quotationAmount'])
          : _toDouble(data['price']);

      final invoiceRef = _firestore.collection('invoices').doc(requestId);
      final batch = _firestore.batch();

      batch.set(invoiceRef, {
        'invoiceId': requestId,
        'requestId': requestId,
        'paymentId': paymentId,
        'customerId': data['customerId'],
        'customerName': data['customerName'],
        'customerEmail': data['customerEmail'],
        'technicianId': _technicianId,
        'technicianName': data['technicianName'] ?? _technicianName,
        'serviceName': data['serviceName'],
        'categoryName': data['categoryName'],
        'amount': amount,
        'totalAmount': amount,
        'paymentMethod': data['paymentMethod'],
        'transactionId': data['transactionId'],
        'paymentStatus': 'paid',
        'status': 'issued',
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(requestRef, {
        'status': 'completed',
        'invoiceId': requestId,
        'invoiceStatus': 'issued',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = _firestore.collection('request_status_history').doc();
      batch.set(historyRef, {
        'requestId': requestId,
        'status': 'completed',
        'changedBy': 'technician',
        'technicianId': _technicianId,
        'technicianName': _technicianName,
        'invoiceId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final customerId = data['customerId']?.toString() ?? '';
      if (customerId.isNotEmpty) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': customerId,
          'requestId': requestId,
          'serviceRequestId': requestId,
          'type': 'invoice_ready',
          'notificationType': 'invoice_ready',
          'title': 'Repair Completed',
          'message':
              'Your repair has been completed. Your invoice is now available.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _showMessage('Repair completed. Invoice created successfully.');
    } catch (e) {
      _showMessage('Complete repair failed: $e');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
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
      case 'payment_pending':
        return 'Payment Pending';
      case 'payment_paid':
        return 'Payment Paid';
      case 'repairing':
        return 'Repairing';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
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
      case 'payment_pending':
        return Colors.orange;
      case 'payment_paid':
        return Colors.green.shade700;
      case 'repairing':
        return Colors.cyan.shade800;
      case 'completed':
        return Colors.green.shade800;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(dynamic value) {
    final amount = _toDouble(value);
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _actionButton(String requestId, Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';

    switch (status) {
      case 'assigned':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _rejectJob(requestId),
                icon: const Icon(Icons.close),
                label: const Text(
                  'Reject',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _acceptJob(requestId),
                icon: const Icon(Icons.check),
                label: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        return _fullButton(
          'ON THE WAY',
          Icons.directions_car,
          primaryColor,
          () => _updateJobStatus(requestId, 'on_the_way'),
        );

      case 'on_the_way':
        return _fullButton(
          'ARRIVED AT LOCATION',
          Icons.location_on,
          Colors.teal,
          () => _updateJobStatus(requestId, 'arrived'),
        );

      case 'arrived':
        return _fullButton(
          'START INSPECTION',
          Icons.search,
          Colors.amber.shade800,
          () => _updateJobStatus(requestId, 'inspection'),
        );

      case 'inspection':
        return _fullButton(
          'CREATE QUOTATION',
          Icons.receipt_long,
          Colors.purple,
          () => _showQuotationDialog(requestId, data),
        );

      case 'quotation':
        return _waitingCard(
          'Waiting for customer approval.',
          Icons.hourglass_top,
        );

      case 'customer_approved':
        return _waitingCard(
          'Quotation approved. Waiting for payment.',
          Icons.payment,
        );

      case 'payment_pending':
        return _waitingCard(
          'Payment waiting for admin verification.',
          Icons.pending,
        );

      case 'payment_paid':
        return _fullButton(
          'START REPAIR WORK',
          Icons.build,
          Colors.cyan.shade800,
          () => _updateJobStatus(requestId, 'repairing'),
        );

      case 'repairing':
        return _fullButton(
          'COMPLETE REPAIR',
          Icons.check_circle,
          Colors.green.shade700,
          () => _completeRepair(requestId, data),
        );

      case 'completed':
        return _waitingCard(
          'Job completed. Invoice issued.',
          Icons.check_circle,
        );

      case 'rejected':
        return _waitingCard('This job was rejected.', Icons.cancel);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _fullButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _waitingCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewWidget(String requestId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('reviews').doc(requestId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final reviewData = snapshot.data!.data() ?? {};
        final rating = _toDouble(reviewData['rating']);
        final comment = reviewData['comment']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'Customer Rating: $rating / 5.0',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '"$comment"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.brown.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final requestId = doc.id;
    final serviceName = data['serviceName']?.toString() ?? 'Service';
    final categoryName = data['categoryName']?.toString() ?? '';
    final customerName = data['customerName']?.toString() ?? 'Customer';
    final status = data['status']?.toString().toLowerCase() ?? '';
    final amount = data['quotationAmount'] ?? data['price'] ?? 0;
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.home_repair_service_rounded,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (categoryName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Customer: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estimated Amount: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  '${_formatAmount(amount)} Ks',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _actionButton(requestId, data),
            _buildReviewWidget(requestId),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar(List<String> categories) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: primaryColor.withValues(alpha: 0.15),
              checkmarkColor: primaryColor,
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTechnician) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_technicianId.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Technician Dashboard'),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: const Center(child: Text('Technician account not found.')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            // 🌟 ဓာတ်ပုံ (Profile Avatar) ထည့်သွင်းပြသခြင်း
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _technicianProfileImage.isNotEmpty
                  ? NetworkImage(_technicianProfileImage)
                  : null,
              child: _technicianProfileImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _technicianName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  // 🌟 ID No. ကို Header တွင် ဖော်ပြပေးခြင်း
                  Text(
                    _technicianIdNumber.isNotEmpty ? 'ID: $_technicianIdNumber' : 'Technician Portal',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 💰 My Earnings Button
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0F172A)),
            tooltip: 'My Earnings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TechnicianEarningsScreen(technicianId: _technicianId),
                ),
              );
            },
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('notifications')
                .where('userId', isEqualTo: _technicianId)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final unreadCount = docs
                  .where((doc) => !(doc.data()['isRead'] as bool? ?? false))
                  .length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF0F172A),
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationListScreen(
                            userId: _technicianId,
                            title: 'Technician Notifications',
                          ),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF0F172A),
            ),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(
                    collectionName: 'technicians',
                    userRole: 'technician',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('service_requests')
            .where('technicianId', isEqualTo: _technicianId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          if (allDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No assigned jobs.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final categories = <String>{'All'};
          for (var doc in allDocs) {
            final cat = doc.data()['categoryName']?.toString();
            if (cat != null && cat.isNotEmpty) {
              categories.add(cat);
            }
          }

          final filteredDocs = allDocs.where((doc) {
            if (_selectedCategory == 'All') return true;
            return doc.data()['categoryName']?.toString() == _selectedCategory;
          }).toList();

          filteredDocs.sort((a, b) {
            final aTime = a.data()['createdAt'] as Timestamp?;
            final bTime = b.data()['createdAt'] as Timestamp?;
            return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
              aTime?.millisecondsSinceEpoch ?? 0,
            );
          });

          return Column(
            children: [
              const SizedBox(height: 8),
              _buildCategoryFilterBar(categories.toList()),
              const SizedBox(height: 12),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text(
                          'No jobs in "$_selectedCategory"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTechnician,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(filteredDocs[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 💰 Technician ၏ ကိုယ်ပိုင် ဝင်ငွေနှင့် အသားတင် (Net Earnings) ပြသသည့် Screen
class TechnicianEarningsScreen extends StatelessWidget {
  final String technicianId;
  const TechnicianEarningsScreen({super.key, required this.technicianId});

  final double adminCommissionPercent = 10.0; // Admin ယူမည့် Commission %

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings & History'),
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .where('technicianId', isEqualTo: technicianId)
            .where('status', whereIn: ['completed', 'payment_paid'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          double myTotalNetEarnings = 0.0;

          for (var doc in docs) {
            final data = doc.data();
            double labor = _toDouble(data['laborCost'] ?? data['labor_cost'] ?? data['price']);
            
            // Labor ထဲမှ Admin ယူမည့် ၁၀% ကော်မရှင်ကို နှုတ်ပြီးမှ Tech ရမည်
            double commission = (labor * adminCommissionPercent) / 100;
            double net = labor - commission;

            myTotalNetEarnings += net;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ကျွန်ုပ်၏ စုစုပေါင်း အသားတင်ဝင်ငွေ (Net Earnings)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${myTotalNetEarnings.toStringAsFixed(0)} Ks',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'စုစုပေါင်း ပြီးစီးခဲ့သော အလုပ်: ${docs.length} ခု',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'အလုပ်များ၏ အသေးစိတ်စာရင်း',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...docs.map((doc) {
                final data = doc.data();
                final serviceName = data['serviceName']?.toString() ?? 'Service';
                double labor = _toDouble(data['laborCost'] ?? data['labor_cost'] ?? data['price']);
                double commission = (labor * adminCommissionPercent) / 100;
                double net = labor - commission;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Labor: ${labor.toStringAsFixed(0)} Ks (Admin Fee: -${commission.toStringAsFixed(0)} Ks)'),
                    trailing: Text(
                      '${net.toStringAsFixed(0)} Ks',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}