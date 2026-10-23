import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF6F8FC);
  static const Color _text = Color(0xFF172033);
  static const Color _muted = Color(0xFF64748B);

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      _showMessage('ဖုန်းနံပါတ် မရှိပါ။');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phoneNumber.trim());

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('ဖုန်းခေါ်ဆို၍ မရပါ။');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('ဖုန်းခေါ်ဆို၍ မရပါ။');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

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
      case 'quotation_sent':
        return 'Quotation Sent';
      case 'customer_approved':
      case 'approved':
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
        return status.isEmpty ? 'Unknown' : status.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'payment_pending':
        return const Color(0xFFD97706);
      case 'assigned':
      case 'accepted':
        return const Color(0xFF2563EB);
      case 'rejected':
      case 'customer_rejected':
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'on_the_way':
        return const Color(0xFF7C3AED);
      case 'arrived':
        return const Color(0xFF0D9488);
      case 'inspection':
        return const Color(0xFFB45309);
      case 'quotation':
      case 'quotation_sent':
        return const Color(0xFF9333EA);
      case 'customer_approved':
      case 'approved':
      case 'completed':
      case 'payment_paid':
        return const Color(0xFF16A34A);
      case 'repairing':
        return const Color(0xFF0891B2);
      default:
        return _muted;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  void _openQuotation() {
    context.push('/customer/quotation?requestId=${widget.requestId}');
  }

  Future<void> _approveQuotation() async {
    try {
      await _firestore.collection('service_requests').doc(widget.requestId).update({
        'status': 'customer_approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showMessage('Quotation approved successfully.');
    } catch (e) {
      _showMessage('Failed to approve quotation: $e');
    }
  }

  Future<void> _rejectQuotation() async {
    try {
      await _firestore.collection('service_requests').doc(widget.requestId).update({
        'status': 'customer_rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showMessage('Quotation rejected.');
    } catch (e) {
      _showMessage('Failed to reject quotation: $e');
    }
  }

 void _openPayment(Map<String, dynamic> data) {
  final quotationAmount = _toDouble(data['quotationAmount']);
  final amount = quotationAmount > 0
      ? quotationAmount
      : _toDouble(data['price']);

  context.push(
    '/customer/payment',
    extra: {
      'requestId': widget.requestId,
      'serviceName': data['serviceName']?.toString() ?? 'Repair Service',
      'totalAmount': amount,
    },
  );
}
  void _openInvoice() {
    context.push('/customer/invoice', extra: {'requestId': widget.requestId});
  }

  void _openReview(Map<String, dynamic> data) {
    context.push(
      '/customer/review',
      extra: {
        'requestId': widget.requestId,
        'paymentId': data['paymentId']?.toString() ?? '',
        'technicianId': data['technicianId']?.toString() ?? '',
        'technicianName': data['technicianName']?.toString() ?? 'Technician',
        'serviceName': data['serviceName']?.toString() ?? 'Service',
      },
    );
  }

  // 🛠️ Widget? အဖြစ် ပြောင်းလဲထားခြင်း (မရှိလျှင် null ကို ပြန်ပေးမည်)
  Widget? _buildActionButton(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final hasReviewed = data['isReviewed'] == true;

    if (status.contains('quotation') || status == 'quotation_sent') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _actionButton(
            label: 'View Quotation Details',
            icon: Icons.receipt_long_rounded,
            onPressed: _openQuotation,
            color: const Color(0xFF9333EA),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _approveQuotation,
                  icon: const Icon(Icons.check_circle_rounded, size: 19),
                  label: const Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _rejectQuotation,
                  icon: const Icon(Icons.cancel_rounded, size: 19),
                  label: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (status == 'customer_approved' || status == 'approved' || status == 'payment_pending' || status.contains('approve')) {
      return _actionButton(
        label: 'Make Payment',
        icon: Icons.payment_rounded,
        onPressed: () => _openPayment(data),
        color: const Color(0xFF16A34A),
      );
    }

    if (status == 'completed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _actionButton(
            label: 'View Invoice',
            icon: Icons.receipt_long_rounded,
            onPressed: _openInvoice,
          ),
          const SizedBox(height: 12),
          if (!hasReviewed)
            _actionButton(
              label: 'Write a Review',
              icon: Icons.star_outline_rounded,
              onPressed: () => _openReview(data),
              color: const Color(0xFFEA580C),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Text(
                    'Review submitted',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return null; // 👈 ဘာမှမရှိလျှင် null ပြန်မည်
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = _primary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianProfileCard(String technicianId) {
    if (technicianId.isEmpty) {
      return _sectionCard(
        title: 'Technician',
        icon: Icons.engineering_rounded,
        child: const Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(
                Icons.person_search_rounded,
                color: _primary,
                size: 27,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'A technician has not been assigned yet.',
                style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(technicianId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _sectionCard(
            title: 'Assigned Technician',
            icon: Icons.engineering_rounded,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};

        final displayName = data['name']?.toString() ?? '';
        final storedName = data['fullName']?.toString() ?? '';

        final name = displayName.trim().isNotEmpty
            ? displayName
            : storedName.trim().isNotEmpty
            ? storedName
            : 'Technician';

        final phone = data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '';
        final specialization = data['specialization']?.toString() ?? '';
        final email = data['email']?.toString() ?? '';
        
        final photoUrl = data['profileImage']?.toString() ?? 
            data['profileImageUrl']?.toString() ?? 
            data['imageUrl']?.toString() ?? '';

        return _sectionCard(
          title: 'Assigned Technician',
          icon: Icons.engineering_rounded,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: const Color(0xFFDBEAFE),
                    backgroundImage: photoUrl.trim().isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.trim().isEmpty
                        ? const Icon(
                            Icons.engineering_rounded,
                            color: _primary,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (specialization.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            specialization,
                            style: const TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (phone.trim().isNotEmpty)
                    IconButton.filled(
                      tooltip: 'Call Technician',
                      onPressed: () => _makePhoneCall(phone),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        fixedSize: const Size(46, 46),
                      ),
                      icon: const Icon(Icons.call_rounded),
                    ),
                ],
              ),
              if (phone.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                _technicianContactRow(Icons.phone_outlined, phone),
              ],
              if (email.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _technicianContactRow(Icons.email_outlined, email),
              ],
              if (phone.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(phone),
                    icon: const Icon(Icons.call_rounded, size: 19),
                    label: const Text(
                      'Call Technician',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _technicianContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: _muted, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primary, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _muted, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _text,
            size: 20,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('service_requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessageState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load request',
              subtitle: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => setState(() {}),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildMessageState(
              icon: Icons.receipt_long_outlined,
              title: 'Request not found',
              subtitle:
                  'This service request may have been removed or is unavailable.',
              actionLabel: 'Go Back',
              onAction: () => context.pop(),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final serviceName =
              data['serviceName']?.toString() ?? 'Repair Service';
          final categoryName = data['categoryName']?.toString() ?? '';
          final status = data['status']?.toString().toLowerCase() ?? 'pending';
          final technicianId = data['technicianId']?.toString() ?? '';
          final address = data['address']?.toString() ?? '';

          final issueDescription =
              data['note']?.toString() ??
              data['issueDescription']?.toString() ??
              '';

          final quotationAmount = _toDouble(data['quotationAmount']);

          final amount = quotationAmount > 0
              ? quotationAmount
              : _toDouble(data['price']);

          // 🛠️ Action Widget ကို စစ်ဆေးခြင်း (null မဟုတ်မှသာ Next Step Card ပေါ်မည်)
          final actionWidget = _buildActionButton(data);

          return RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              await _firestore
                  .collection('service_requests')
                  .doc(widget.requestId)
                  .get(const GetOptions(source: Source.serverAndCache));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                _buildRequestHeader(
                  serviceName: serviceName,
                  categoryName: categoryName,
                  status: status,
                ),

                const SizedBox(height: 16),

                _buildTechnicianProfileCard(technicianId),

                if (actionWidget != null) ...[
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Next Step',
                    icon: Icons.task_alt_rounded,
                    child: actionWidget,
                  ),
                ],

                const SizedBox(height: 16),

                _sectionCard(
                  title: 'Request Information',
                  icon: Icons.assignment_outlined,
                  child: Column(
                    children: [
                      if (address.trim().isNotEmpty)
                        _detailRow(
                          icon: Icons.location_on_outlined,
                          title: 'Service Address',
                          value: address,
                        ),

                      if (address.trim().isNotEmpty &&
                          issueDescription.trim().isNotEmpty)
                        const SizedBox(height: 18),

                      if (issueDescription.trim().isNotEmpty)
                        _detailRow(
                          icon: Icons.notes_rounded,
                          title: 'Problem Description',
                          value: issueDescription,
                        ),

                      if ((address.trim().isNotEmpty ||
                              issueDescription.trim().isNotEmpty) &&
                          amount > 0)
                        const SizedBox(height: 18),

                      if (amount > 0)
                        _detailRow(
                          icon: Icons.payments_outlined,
                          title: 'Current Amount',
                          value: '${_formatAmount(amount)} Ks',
                        ),

                      if (address.trim().isEmpty &&
                          issueDescription.trim().isEmpty &&
                          amount <= 0)
                        const Text(
                          'No additional request information is available.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: _primary,
                        size: 23,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'You can follow your request status here. Available actions will appear when your request reaches the appropriate stage.',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestHeader({
    required String serviceName,
    required String categoryName,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: _primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      if (categoryName.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          categoryName,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE8EDF5)),
          const SizedBox(height: 17),

          const Text(
            'REQUEST STATUS',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}