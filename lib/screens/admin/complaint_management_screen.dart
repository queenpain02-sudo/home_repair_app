import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComplaintManagementScreen extends StatelessWidget {
  const ComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint & Support Management')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No complaints found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;
              final title = data['title'] ?? 'No Title';
              final desc = data['description'] ?? '';
              final customer = data['customerName'] ?? 'Customer';
              final technician = data['technicianName'] ?? 'Technician';
              final status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'From: $customer | Tech: $technician\nStatus: $status\n$desc',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      FirebaseFirestore.instance
                          .collection('complaints')
                          .doc(id)
                          .update({
                            'status': val,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'investigating',
                        child: Text('Mark Investigating'),
                      ),
                      PopupMenuItem(
                        value: 'resolved',
                        child: Text('Mark Resolved'),
                      ),
                      PopupMenuItem(
                        value: 'rejected',
                        child: Text('Reject Complaint'),
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
}
