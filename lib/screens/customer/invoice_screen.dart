import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InvoiceScreen extends StatefulWidget {
  final String requestId;

  const InvoiceScreen({super.key, required this.requestId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _hasReview = false;
  bool _checkingReview = true;

  @override
  void initState() {
    super.initState();
    _checkReview();
  }

  Future<void> _checkReview() async {
    try {
      final doc = await _firestore
          .collection('reviews')
          .doc(widget.requestId)
          .get();

      if (!mounted) return;

      setState(() {
        _hasReview = doc.exists;
        _checkingReview = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingReview = false;
      });
    }
  }

  Future<void> _openReview(
    Map<String, dynamic> requestData,
    Map<String, dynamic> invoiceData,
  ) async {
    final paymentId =
        invoiceData['paymentId']?.toString() ??
        requestData['paymentId']?.toString() ??
        '';

    final technicianId =
        invoiceData['technicianId']?.toString() ??
        requestData['technicianId']?.toString() ??
        '';

    final technicianName =
        invoiceData['technicianName']?.toString() ??
        requestData['technicianName']?.toString() ??
        'Technician';

    final serviceName =
        invoiceData['serviceName']?.toString() ??
        requestData['serviceName']?.toString() ??
        'Service';

    try {
      final result = await context.push(
        '/customer/review',
        extra: {
          'requestId': widget.requestId,
          'paymentId': paymentId,
          'technicianId': technicianId,
          'technicianName': technicianName,
          'serviceName': serviceName,
        },
      );

      if (!mounted) return;

      if (result == true) {
        await _checkReview();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open review screen.\n$e')),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(dynamic value) {
    final amount = _toDouble(value);

    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('service_requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, requestSnapshot) {
          if (requestSnapshot.hasError) {
            return Center(child: Text('Error: ${requestSnapshot.error}'));
          }

          if (requestSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!requestSnapshot.hasData || !requestSnapshot.data!.exists) {
            return const Center(child: Text('Service request not found.'));
          }

          final requestData = requestSnapshot.data!.data() ?? {};

          final status = requestData['status']?.toString() ?? '';

          final invoiceId = requestData['invoiceId']?.toString() ?? '';

          if (status != 'completed' || invoiceId.isEmpty) {
            return _notReady(
              'Invoice is not available yet.',
              'Repair must be completed before the final invoice is issued.',
            );
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('invoices')
                .doc(invoiceId)
                .snapshots(),
            builder: (context, invoiceSnapshot) {
              if (invoiceSnapshot.hasError) {
                return Center(
                  child: Text('Invoice error: ${invoiceSnapshot.error}'),
                );
              }

              if (invoiceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!invoiceSnapshot.hasData || !invoiceSnapshot.data!.exists) {
                return _notReady(
                  'Invoice is being prepared.',
                  'The repair is completed. Please check again shortly.',
                );
              }

              final invoiceData = invoiceSnapshot.data!.data() ?? {};

              return _buildInvoice(requestData, invoiceData);
            },
          );
        },
      ),
    );
  }

  Widget _notReady(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoice(
    Map<String, dynamic> requestData,
    Map<String, dynamic> invoiceData,
  ) {
    final serviceName =
        invoiceData['serviceName']?.toString() ??
        requestData['serviceName']?.toString() ??
        'Service';

    final technicianName =
        invoiceData['technicianName']?.toString() ??
        requestData['technicianName']?.toString() ??
        'Technician';

    final amount =
        invoiceData['amount'] ??
        invoiceData['totalAmount'] ??
        requestData['quotationAmount'] ??
        requestData['price'] ??
        0;

    final paymentMethod =
        invoiceData['paymentMethod']?.toString() ??
        requestData['paymentMethod']?.toString() ??
        '';

    final transactionId =
        invoiceData['transactionId']?.toString() ??
        requestData['transactionId']?.toString() ??
        '';

    final invoiceId =
        invoiceData['invoiceId']?.toString() ??
        requestData['invoiceId']?.toString() ??
        widget.requestId;

    final completedAt =
        invoiceData['completedAt'] ?? requestData['completedAt'];

    final paymentStatus =
        invoiceData['paymentStatus']?.toString() ??
        requestData['paymentStatus']?.toString() ??
        'paid';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _invoiceHeader(),

          const SizedBox(height: 16),

          _invoiceCard(
            serviceName: serviceName,
            technicianName: technicianName,
            amount: amount,
            paymentMethod: paymentMethod,
            transactionId: transactionId,
            invoiceId: invoiceId,
            completedAt: completedAt,
            paymentStatus: paymentStatus,
          ),

          const SizedBox(height: 16),

          if (_checkingReview)
            const SizedBox(
              height: 52,
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!_checkingReview && !_hasReview)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openReview(requestData, invoiceData);
                },
                icon: const Icon(Icons.star),
                label: const Text(
                  'RATE SERVICE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          if (!_checkingReview && _hasReview)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have already submitted a review.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _invoiceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 55),
          const SizedBox(height: 8),
          const Text(
            'PAID',
            style: TextStyle(
              color: Colors.green,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('Final Invoice', style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _invoiceCard({
    required String serviceName,
    required String technicianName,
    required dynamic amount,
    required String paymentMethod,
    required String transactionId,
    required String invoiceId,
    required dynamic completedAt,
    required String paymentStatus,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _row('Invoice ID', invoiceId),
            _row('Service', serviceName),
            _row('Technician', technicianName),
            _row('Payment Status', paymentStatus.toUpperCase()),
            _row('Payment Method', paymentMethod),
            _row('Transaction ID', transactionId),
            _row('Completed At', _formatDate(completedAt)),

            const Divider(height: 28),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_formatAmount(amount)} Ks',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty || value == '-') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
