import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final String? requestId;   
  final double materialCost; 
  final double serviceCost; 
  final double laborCost;    

  const PaymentScreen({
    super.key,
    this.requestId,
    this.materialCost = 0.0,
    this.serviceCost = 0.0,
    this.laborCost = 0.0,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPromoCode;
  double _discountPercentage = 0.0;
  String _selectedPaymentMethod = 'Cash on Delivery'; 
  bool _isProcessing = false;
  bool _isLoadingData = true;

  double _materialCost = 0.0;
  double _serviceCost = 0.0; 
  double _laborCost = 0.0;

  @override
  void initState() {
    super.initState();
    _materialCost = widget.materialCost;
    _serviceCost = widget.serviceCost;
    _laborCost = widget.laborCost;
    
    _fetchCostFromFirestore();
  }

  double _parseCost(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // 🔍 Firestore မှ Cost များကို အမှားအယွင်းမရှိ 100% ဆွဲထုတ်ခြင်း[cite: 2]
  Future<void> _fetchCostFromFirestore() async {
    if (widget.requestId == null || widget.requestId!.isEmpty) {
      setState(() {
        _isLoadingData = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(widget.requestId)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _materialCost = _parseCost(data['partsCost'] ?? data['materialCost'] ?? widget.materialCost);
          _serviceCost = _parseCost(data['serviceCost'] ?? data['servicecost'] ?? data['serviceFee'] ?? widget.serviceCost);
          _laborCost = _parseCost(data['laborCost'] ?? data['labor_cost'] ?? widget.laborCost);
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cost: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  double get _laborDiscountAmount {
    if (_selectedPromoCode == null || _discountPercentage <= 0) {
      return 0.0;
    }
    return (_laborCost * _discountPercentage) / 100;
  }

  double get _finalTotalAmount {
    double finalLabor = _laborCost - _laborDiscountAmount;
    return _materialCost + _serviceCost + finalLabor;
  }

  // 🏷️ Promocodes များကို Firestore မှ သေချာစွာ လှမ်းဆွဲပြသပေးမည့် Function[cite: 2]
 Future<void> _showLaborPromoSelector() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ရယူနိုင်သော Promocode များ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('promocodes').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // အကယ်၍ Firestore ထဲမှာ ဘာမှမရှိသေးရင် Default တစ်ခုပြမယ်
                    if (docs.isEmpty) {
                      return ListView(
                        children: [
                          Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF0F4C5C),
                                child: Icon(Icons.local_offer, color: Colors.white, size: 20),
                              ),
                              title: const Text('LABOR10', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))),
                              subtitle: const Text('လက်ခအတွက် ၁၀% အထူးလျှော့စျေး'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F4C5C),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedPromoCode = 'LABOR10';
                                    _discountPercentage = 10.0;
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('သုံးမည်'),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final code = data['code'] ?? docs[index].id;
                        final discount = _parseCost(data['discount']);
                        final description = data['description'] ?? '';

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF0F4C5C),
                              child: Icon(Icons.local_offer, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C)),
                            ),
                            subtitle: Text(description),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C5C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedPromoCode = code;
                                  _discountPercentage = discount;
                                });
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Promocode "$code" ကို ရွေးချယ်ပြီးပါပြီ။')),
                                );
                              },
                              child: const Text('သုံးမည်'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _processPayment() async {
    if (_finalTotalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ငွေပေးချေရမည့် ပမာဏ မမှန်ကန်ပါ။'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final double amountToPay = _finalTotalAmount;

    try {
      if (_selectedPromoCode != null && user != null) {
        await FirebaseFirestore.instance.collection('user_promos').add({
          'userId': user.uid,
          'promoCode': _selectedPromoCode,
          'usedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('ငွေပေးချေမှု အောင်မြင်ပါသည်'),
          content: Text(
              'စုစုပေါင်း ငွေပမာဏ ${amountToPay.toStringAsFixed(0)} ကျပ် ကို ($_selectedPaymentMethod) ဖြင့် ပေးချေရန် အတည်ပြုပြီးပါပြီ။'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout & Payment'),
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1️⃣ Promocode ရွေးချယ်ရန်[cite: 3]
                  const Text('Promocode (ဝန်ဆောင်ခအတွက်)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isProcessing ? null : _showLaborPromoSelector,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer_outlined, color: Color(0xFF0F4C5C)),
                              const SizedBox(width: 12),
                              Text(
                                _selectedPromoCode ?? 'Promocode နှိပ်၍ ရွေးချယ်ရန်',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPromoCode != null ? Colors.black87 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_selectedPromoCode != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedPromoCode = null;
                                      _discountPercentage = 0.0;
                                    });
                                  },
                                ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2️⃣ ငွေပေးချေမည့် နည်းလမ်းများ[cite: 3]
                  const Text('ငွေပေးချေမည့် နည်းလမ်း',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Cash on Delivery (လက်ငင်းငွေချေမည်)'),
                          value: 'Cash on Delivery',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('KBZ Pay'),
                          value: 'KBZ Pay',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('Wave Pay'),
                          value: 'Wave Pay',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3️⃣ Bill Summary[cite: 3]
                  const Text('ငွေပေးချေရန် အသေးစိတ်',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ပစ္စည်းတန်ဖိုး (Material Cost):'),
                            Text('${_materialCost.toStringAsFixed(0)} ကျပ်'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ဝန်ဆောင်ခ (Service Cost):'),
                            Text('${_serviceCost.toStringAsFixed(0)} ကျပ်'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('လက်ခ (Labor Cost):'),
                            Text('${_laborCost.toStringAsFixed(0)} ကျပ်'),
                          ],
                        ),
                        
                        if (_selectedPromoCode != null && _discountPercentage > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Labor လျှော့ငွေ ($_selectedPromoCode - ${_discountPercentage.toStringAsFixed(0)}%):'),
                              Text(
                                '- ${_laborDiscountAmount.toStringAsFixed(0)} ကျပ်',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('စုစုပေါင်း ပေးချေရမည့်ငွေ:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '${_finalTotalAmount.toStringAsFixed(0)} ကျပ်',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C5C)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 4️⃣ Confirm Button[cite: 3]
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _processPayment,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'ငွေပေးချေမှုကို အတည်ပြုမည်',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}