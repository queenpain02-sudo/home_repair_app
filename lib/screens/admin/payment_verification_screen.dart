import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProcessing = false;

  Future<void> _approvePayment({
    required String paymentId,
    required String requestId,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentRef = _firestore.collection('payments').doc(paymentId);
      final requestRef = _firestore
          .collection('service_requests')
          .doc(requestId);

      final paymentSnapshot = await paymentRef.get();
      final requestSnapshot = await requestRef.get();

      if (!paymentSnapshot.exists) {
        throw Exception('Payment မတွေ့ပါ။');
      }

      if (!requestSnapshot.exists) {
        throw Exception('Service request မတွေ့ပါ။');
      }

      final paymentData = paymentSnapshot.data() ?? {};
      final requestData = requestSnapshot.data() ?? {};

      if (paymentData['status']?.toString() != 'pending') {
        throw Exception(
          'ဒီ payment ကို အရင်ဆုံး process လုပ်ပြီးသားဖြစ်ပါတယ်။',
        );
      }

      final technicianId =
          paymentData['technicianId']?.toString() ??
          requestData['technicianId']?.toString() ??
          '';

      final customerId =
          paymentData['customerId']?.toString() ??
          requestData['customerId']?.toString() ??
          '';

      final transactionId =
          paymentData['transactionId']?.toString() ??
          requestData['transactionId']?.toString() ??
          '';

      final paymentMethod =
          paymentData['paymentMethod']?.toString() ??
          requestData['paymentMethod']?.toString() ??
          '';

      final batch = _firestore.batch();

      batch.update(paymentRef, {
        'status': 'paid',
        'verifiedBy': 'admin',
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(requestRef, {
        'status': 'payment_paid',
        'paymentStatus': 'paid',
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'paymentVerifiedAt': FieldValue.serverTimestamp(),
        'paymentVerifiedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = _firestore.collection('request_status_history').doc();

      batch.set(historyRef, {
        'requestId': requestId,
        'status': 'payment_paid',
        'changedBy': 'admin',
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔔 Technician Notification (requestId, serviceRequestId နှစ်မျိုးလုံး ထည့်ထားသည်)
      if (technicianId.isNotEmpty) {
        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': technicianId,
          'requestId': requestId,
          'serviceRequestId': requestId,
          'type': 'payment_verified',
          'notificationType': 'payment_verified',
          'title': 'Payment Verified',
          'message':
              'Customer payment has been verified. You can now start the repair.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 🔔 Customer Notification (requestId, serviceRequestId နှစ်မျိုးလုံး ထည့်ထားသည်)
      if (customerId.isNotEmpty) {
        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': customerId,
          'requestId': requestId,
          'serviceRequestId': requestId,
          'type': 'payment_verified',
          'notificationType': 'payment_verified',
          'title': 'Payment Confirmed',
          'message':
              'Your payment has been verified. The technician can now start the repair.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _showMessage('Payment approved successfully.');
    } on FirebaseException catch (e) {
      _showMessage(e.message ?? 'Payment approval failed.');
    } catch (e) {
      _showMessage('Payment approval failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectPayment({
    required String paymentId,
    required String requestId,
  }) async {
    if (_isProcessing) return;

    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Payment'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Enter rejection reason',
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
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  reasonController.text.trim().isEmpty
                      ? 'Payment rejected by admin.'
                      : reasonController.text.trim(),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentRef = _firestore.collection('payments').doc(paymentId);
      final requestRef = _firestore
          .collection('service_requests')
          .doc(requestId);

      final requestSnapshot = await requestRef.get();

      if (!requestSnapshot.exists) {
        throw Exception('Service request မတွေ့ပါ။');
      }

      final requestData = requestSnapshot.data() ?? {};

      final customerId = requestData['customerId']?.toString() ?? '';

      final batch = _firestore.batch();

      batch.update(paymentRef, {
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedBy': 'admin',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(requestRef, {
        'paymentStatus': 'rejected',
        'paymentRejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = _firestore.collection('request_status_history').doc();

      batch.set(historyRef, {
        'requestId': requestId,
        'status': 'payment_rejected',
        'changedBy': 'admin',
        'paymentId': paymentId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔔 Customer Rejection Notification
      if (customerId.isNotEmpty) {
        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': customerId,
          'requestId': requestId,
          'serviceRequestId': requestId,
          'type': 'payment_rejected',
          'notificationType': 'payment_rejected',
          'title': 'Payment Rejected',
          'message': reason,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _showMessage('Payment rejected.');
    } on FirebaseException catch (e) {
      _showMessage(e.message ?? 'Payment rejection failed.');
    } catch (e) {
      _showMessage('Payment rejection failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  double _getPaymentAmount(Map<String, dynamic> data) {
    if (data['finalAmount'] != null && _toDouble(data['finalAmount']) > 0) {
      return _toDouble(data['finalAmount']);
    }
    if (data['amount'] != null && _toDouble(data['amount']) > 0) {
      return _toDouble(data['amount']);
    }
    if (data['originalAmount'] != null &&
        _toDouble(data['originalAmount']) > 0) {
      return _toDouble(data['originalAmount']);
    }
    return 0.0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Verification')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('payments')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 12),
                  Text('No pending payments.', style: TextStyle(fontSize: 17)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final paymentId = data['paymentId']?.toString() ?? doc.id;
              final requestId = data['requestId']?.toString() ?? '';
              final serviceName = data['serviceName']?.toString() ?? 'Service';
              final customerName = data['customerName']?.toString() ?? '';
              final method = data['paymentMethod']?.toString() ?? '';
              final transactionId = data['transactionId']?.toString() ?? '';

              final paymentAmount = _getPaymentAmount(data);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _info('Customer', customerName),
                      _info('Amount', '${_formatAmount(paymentAmount)} Ks'),
                      _info('Payment Method', method),
                      _info('Transaction ID', transactionId),
                      _info('Request ID', requestId),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _rejectPayment(
                                      paymentId: paymentId,
                                      requestId: requestId,
                                    ),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _approvePayment(
                                      paymentId: paymentId,
                                      requestId: requestId,
                                    ),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                            ),
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
      ),
    );
  }

  Widget _info(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
