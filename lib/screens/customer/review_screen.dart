import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReviewScreen extends StatefulWidget {
  final String requestId;
  final String paymentId;
  final String technicianId;
  final String technicianName;
  final String serviceName;

  const ReviewScreen({
    super.key,
    required this.requestId,
    required this.paymentId,
    required this.technicianId,
    required this.technicianName,
    required this.serviceName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  int _serviceQuality = 0;
  int _priceRating = 0;
  int _onTimeRating = 0;

  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ============================================================
  // RATING STARS
  // ============================================================

  Widget _ratingStars({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;

        return IconButton(
          onPressed: _submitting
              ? null
              : () {
                  onChanged(starNumber);
                },
          icon: Icon(
            starNumber <= value ? Icons.star : Icons.star_border,
            size: 34,
            color: Colors.amber.shade700,
          ),
        );
      }),
    );
  }

  // ============================================================
  // CRITERIA CARD
  // ============================================================

  Widget _criteriaCard({
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            _ratingStars(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT REVIEW
  // ============================================================

  Future<void> _submitReview() async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE OVERALL RATING
    // ----------------------------------------------------------

    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an overall rating.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE SERVICE QUALITY
    // ----------------------------------------------------------

    if (_serviceQuality < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the service quality.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE PRICE
    // ----------------------------------------------------------

    if (_priceRating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the price.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE ON TIME
    // ----------------------------------------------------------

    if (_onTimeRating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the technician on-time service.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _submitting = true;
    });

    try {
      // ========================================================
      // CHECK EXISTING REVIEW
      // ========================================================

      final reviewRef = _firestore.collection('reviews').doc(widget.requestId);

      final existingReview = await reviewRef.get();

      if (existingReview.exists) {
        throw Exception('You have already reviewed this repair.');
      }

      // ========================================================
      // GET CUSTOMER PROFILE
      // ========================================================

      String customerName = user.displayName ?? '';

      String customerEmail = user.email ?? '';

      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() ?? {};

        customerName =
            userData['name']?.toString() ??
            userData['displayName']?.toString() ??
            customerName;

        customerEmail = userData['email']?.toString() ?? customerEmail;
      }

      // ========================================================
      // GET SERVICE REQUEST
      // ========================================================

      final requestSnapshot = await _firestore
          .collection('service_requests')
          .doc(widget.requestId)
          .get();

      if (!requestSnapshot.exists) {
        throw Exception('Service request not found.');
      }

      final requestData = requestSnapshot.data() ?? {};

      // ========================================================
      // GET ACTUAL DATA FROM REQUEST
      // ========================================================

      final actualTechnicianId =
          requestData['technicianId']?.toString() ?? widget.technicianId;

      final actualTechnicianName =
          requestData['technicianName']?.toString() ?? widget.technicianName;

      final actualServiceName =
          requestData['serviceName']?.toString() ?? widget.serviceName;

      final actualPaymentId =
          requestData['paymentId']?.toString() ?? widget.paymentId;

      // ========================================================
      // SAVE REVIEW
      // ========================================================

      await reviewRef.set({
        'reviewId': reviewRef.id,
        'requestId': widget.requestId,

        'paymentId': actualPaymentId,

        'customerId': user.uid,
        'customerName': customerName,
        'customerEmail': customerEmail,

        'technicianId': actualTechnicianId,
        'technicianName': actualTechnicianName,

        'serviceId': requestData['serviceId']?.toString(),

        'serviceName': actualServiceName,

        'rating': _rating,
        'serviceQuality': _serviceQuality,
        'priceRating': _priceRating,
        'onTimeRating': _onTimeRating,

        'comment': _commentController.text.trim(),

        'createdAt': FieldValue.serverTimestamp(),

        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // UPDATE SERVICE REQUEST
      // ========================================================

      await _firestore
          .collection('service_requests')
          .doc(widget.requestId)
          .update({
            'reviewId': reviewRef.id,
            'reviewStatus': 'completed',
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // ========================================================
      // STATUS HISTORY
      // ========================================================

      await _firestore.collection('request_status_history').add({
        'requestId': widget.requestId,
        'status': 'reviewed',
        'changedBy': 'customer',
        'changedById': user.uid,
        'reviewId': reviewRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // NOTIFY TECHNICIAN
      // ========================================================

      if (actualTechnicianId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': actualTechnicianId,
          'title': 'New Customer Review',
          'message': '$customerName rated your repair service $_rating/5.',
          'type': 'review_received',
          'requestId': widget.requestId,
          'reviewId': reviewRef.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your review has been submitted.'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to InvoiceScreen
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Technician')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====================================================
            // TECHNICIAN
            // ====================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      child: Icon(Icons.engineering, size: 38),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      widget.technicianName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.serviceName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // OVERALL RATING
            // ====================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'Overall Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'How satisfied are you with the repair service?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 8),

                    _ratingStars(
                      value: _rating,
                      onChanged: (value) {
                        setState(() {
                          _rating = value;
                        });
                      },
                    ),

                    if (_rating > 0)
                      Text(
                        '$_rating / 5',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // SERVICE DETAILS
            // ====================================================
            const Text(
              'Service Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _criteriaCard(
              title: 'Service Quality',
              subtitle: 'How good was the repair work?',
              value: _serviceQuality,
              onChanged: (value) {
                setState(() {
                  _serviceQuality = value;
                });
              },
            ),

            _criteriaCard(
              title: 'Price',
              subtitle: 'Was the price reasonable?',
              value: _priceRating,
              onChanged: (value) {
                setState(() {
                  _priceRating = value;
                });
              },
            ),

            _criteriaCard(
              title: 'On Time',
              subtitle: 'Did the technician arrive and finish on time?',
              value: _onTimeRating,
              onChanged: (value) {
                setState(() {
                  _onTimeRating = value;
                });
              },
            ),

            const SizedBox(height: 8),

            // ====================================================
            // COMMENT
            // ====================================================
            const Text(
              'Comment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _commentController,
              enabled: !_submitting,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write your feedback...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // SUBMIT
            // ====================================================
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitReview,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _submitting ? 'Submitting...' : 'Submit Review',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
