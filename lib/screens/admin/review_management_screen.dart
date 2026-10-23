import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewManagementScreen extends StatelessWidget {
  const ReviewManagementScreen({super.key});

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('createdAt', descending: true)
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
                  'Unable to load reviews.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reviews yet.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Customer reviews will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // ============================================================
          // CALCULATE STATISTICS
          // ============================================================

          double totalRating = 0;

          final Map<String, List<double>> technicianRatings = {};

          for (final doc in documents) {
            final data = doc.data();

            final ratingValue = data['rating'];

            final rating = ratingValue is num
                ? ratingValue.toDouble()
                : double.tryParse(ratingValue?.toString() ?? '') ?? 0;

            totalRating += rating;

            final technicianId = data['technicianId']?.toString() ?? '';

            if (technicianId.isNotEmpty) {
              technicianRatings.putIfAbsent(technicianId, () => []);

              technicianRatings[technicianId]!.add(rating);
            }
          }

          final overallRating = documents.isEmpty
              ? 0.0
              : totalRating / documents.length;

          return RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .limit(1)
                  .get();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ========================================================
                // SUMMARY CARDS
                // ========================================================

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.rate_review,
                        title: 'Total Reviews',
                        value: documents.length.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.star,
                        title: 'Average Rating',
                        value: overallRating.toStringAsFixed(1),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ========================================================
                // TECHNICIAN RATINGS
                // ========================================================
                const Text(
                  'Technician Ratings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (technicianRatings.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.engineering_outlined,
                            size: 50,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 10),
                          const Text('No technician ratings yet.'),
                        ],
                      ),
                    ),
                  )
                else
                  ...technicianRatings.entries.map((entry) {
                    final technicianId = entry.key;
                    final ratings = entry.value;

                    final average =
                        ratings.reduce((a, b) => a + b) / ratings.length;

                    String technicianName = technicianId;

                    for (final doc in documents) {
                      final data = doc.data();

                      if (data['technicianId']?.toString() == technicianId) {
                        technicianName =
                            data['technicianName']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true
                            ? data['technicianName'].toString()
                            : technicianId;

                        break;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.orange.withValues(
                                alpha: 0.12,
                              ),
                              child: const Icon(
                                Icons.engineering,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    technicianName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${ratings.length} review'
                                    '${ratings.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      average.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Average',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // ========================================================
                // CUSTOMER REVIEWS
                // ========================================================
                const Text(
                  'Customer Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ...documents.map((doc) {
                  final data = doc.data();

                  final customerName =
                      data['customerName']?.toString() ?? 'Customer';

                  final technicianName =
                      data['technicianName']?.toString() ?? 'Technician';

                  final serviceName =
                      data['serviceName']?.toString() ?? 'Service';

                  final comment = data['comment']?.toString() ?? '';

                  final ratingValue = data['rating'];

                  final rating = ratingValue is num
                      ? ratingValue.toDouble()
                      : double.tryParse(ratingValue?.toString() ?? '') ?? 0;

                  final createdAt = data['createdAt'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer + Rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                child: Text(
                                  customerName.isNotEmpty
                                      ? customerName[0].toUpperCase()
                                      : 'C',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...List.generate(5, (index) {
                                          return Icon(
                                            index < rating.round()
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.orange,
                                            size: 19,
                                          );
                                        }),
                                        const SizedBox(width: 6),
                                        Text(
                                          rating.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 24),

                          // Service
                          Row(
                            children: [
                              const Icon(
                                Icons.build,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  serviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Technician
                          Row(
                            children: [
                              const Icon(
                                Icons.engineering,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Technician: '
                                  '$technicianName',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),

                          if (comment.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                comment,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
