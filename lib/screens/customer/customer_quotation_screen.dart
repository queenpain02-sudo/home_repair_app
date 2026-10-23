import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerQuotationScreen extends StatelessWidget {
  final String? requestId;

  const CustomerQuotationScreen({
    super.key,
    this.requestId,
  });

  double _parseCost(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (requestId == null || requestId!.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quotation Details")),
        body: const Center(child: Text("Invalid Request ID")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Quotation Details (ID: $requestId)"),
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Quotation not found.'));
          }

          final data = snapshot.data!.data() ?? {};
          final serviceName = data['serviceName']?.toString() ?? 'Repair Service';
          
          final materialCost = _parseCost(data['partsCost'] ?? data['materialCost']);
          final serviceCost = _parseCost(data['serviceCost'] ?? data['servicecost'] ?? data['serviceFee']);
          final laborCost = _parseCost(data['laborCost'] ?? data['serviceFee']);
          
          double quotationAmount = _parseCost(data['totalAmount'] ?? data['quotationAmount'] ?? data['price']);
          if (quotationAmount <= 0) {
            quotationAmount = materialCost + serviceCost + laborCost;
          }

          final items = data['quotationItems'] as List<dynamic>? ?? data['items'] as List<dynamic>? ?? [];
          final quotationNote = data['quotationNote']?.toString() ?? 
                                data['inspectionNote']?.toString() ??
                                data['note']?.toString() ?? 
                                data['description']?.toString() ?? 
                                'No additional notes from technician.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ကုန်ကျစရိတ် အသေးစိတ် (Quotation Breakdown)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(height: 20),
                      if (materialCost > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ပစ္စည်းဖိုး (Material Cost):"),
                            Text("${materialCost.toStringAsFixed(0)} ကျပ်", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (serviceCost > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ဝန်ဆောင်ခ (Service Cost):"),
                            Text("${serviceCost.toStringAsFixed(0)} ကျပ်", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (laborCost > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("လက်ခ (Labor Cost):"),
                            Text("${laborCost.toStringAsFixed(0)} ကျပ်", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const Text("ပါဝင်သော အသေးစိတ်စာရင်း:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        ...items.map((item) {
                          final itemName = item['name']?.toString() ?? item['title']?.toString() ?? 'Item';
                          final itemPrice = _parseCost(item['price'] ?? item['amount']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("- $itemName", style: const TextStyle(fontSize: 14)),
                                Text("${itemPrice.toStringAsFixed(0)} ကျပ်", style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 20),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("စုစုပေါင်း ကျသင့်ငွေ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            "${quotationAmount.toStringAsFixed(0)} ကျပ်",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C5C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Technician မှ မှတ်ချက် / ဖော်ပြချက်:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(quotationNote, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('service_requests')
                          .doc(requestId)
                          .update({
                        'status': 'customer_approved',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (!context.mounted) return;
                      
                      // 💡 ဤနေရာတွင် extra ဖြင့် တန်ဖိုးများကို အပြည့်အစုံ ပို့ပေးသည်[cite: 1]
                      context.push(
                        '/customer/payment',
                        extra: {
                          'requestId': requestId,
                          'materialCost': materialCost,
                          'serviceCost': serviceCost,
                          'laborCost': laborCost,
                        },
                      );
                    },
                    child: const Text("ဤဈေးနှုန်းဖြင့် အတည်ပြုပြီး ငွေပေးချေမည်", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}