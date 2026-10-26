import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final String? requestId;
  final String? serviceName;
  final double? materialCost;
  final double? serviceCost;
  final double? laborCost;
  final double? totalAmount;

  const PaymentScreen({
    super.key,
    this.requestId,
    this.serviceName,
    this.materialCost,
    this.serviceCost,
    this.laborCost,
    this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _transactionController = TextEditingController();

  String? _selectedPromoCode;
  double _discountPercentage = 0.0;
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isProcessing = false;
  bool _isLoadingData = true;

  double _materialCost = 0.0;
  double _serviceCost = 0.0;
  double _laborCost = 0.0;
  double _baseTotalAmount = 0.0;
  String _serviceTitle = 'Repair Service';

  @override
  void initState() {
    super.initState();
    _materialCost = widget.materialCost ?? 0.0;
    _serviceCost = widget.serviceCost ?? 0.0;
    _laborCost = widget.laborCost ?? 0.0;
    _baseTotalAmount = widget.totalAmount ?? 0.0;
    if (widget.serviceName != null && widget.serviceName!.isNotEmpty) {
      _serviceTitle = widget.serviceName!;
    }

    _fetchDetailsFromFirestore();
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  double _parseCost(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _fetchDetailsFromFirestore() async {
    final String? reqId = widget.requestId;
    if (reqId == null || reqId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(reqId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? <String, dynamic>{};
        
        final quotationAmount = _parseCost(data['quotationAmount']);
        final price = quotationAmount > 0 ? quotationAmount : _parseCost(data['price']);

        setState(() {
          _serviceTitle = data['serviceName']?.toString() ?? _serviceTitle;
          _materialCost = _parseCost(data['partsCost'] ?? data['materialCost'] ?? _materialCost);
          _serviceCost = _parseCost(data['serviceCost'] ?? data['servicecost'] ?? data['serviceFee'] ?? _serviceCost);
          _laborCost = _parseCost(data['laborCost'] ?? data['labor_cost'] ?? _laborCost);
          
          if (_materialCost == 0 && _serviceCost == 0 && _laborCost == 0 && _baseTotalAmount == 0) {
            _baseTotalAmount = price;
          }
          
          _isLoadingData = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  double get _discountAmount {
    if (_selectedPromoCode == null || _discountPercentage <= 0) {
      return 0.0;
    }
    final double baseForDiscount = (_laborCost > 0 ? _laborCost : (_baseTotalAmount > 0 ? _baseTotalAmount : (_materialCost + _serviceCost)));
    return (baseForDiscount * _discountPercentage) / 100;
  }

  double get _finalTotalAmount {
    final double subtotal = (_materialCost + _serviceCost + _laborCost) > 0
        ? (_materialCost + _serviceCost + _laborCost)
        : _baseTotalAmount;
    final double total = subtotal - _discountAmount;
    return total < 0 ? 0.0 : total;
  }

  Widget _buildPromoListSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('promocodes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Promocode ရယူရာတွင် Error ရှိနေပါသည်: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildPromoCard(
            code: 'LABOR10',
            discount: 10.0,
            description: 'လက်ခအတွက် ၁၀% အထူးလျှော့စျေး (Default)',
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final String code = (data['code'] ?? data['promoCode'] ?? doc.id).toString();
            final double discount = _parseCost(data['discount']);
            final String description = (data['description'] ?? 'Special discount offer').toString();

            return _buildPromoCard(
              code: code,
              discount: discount,
              description: description,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPromoCard({
    required String code,
    required double discount,
    required String description,
  }) {
    final bool isSelected = _selectedPromoCode == code;

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0F4C5C) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF0F4C5C),
              child: Icon(Icons.local_offer, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$code (${discount.toStringAsFixed(0)}% OFF)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F4C5C),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.red.shade600 : const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    _selectedPromoCode = null;
                    _discountPercentage = 0.0;
                  } else {
                    _selectedPromoCode = code;
                    _discountPercentage = discount;
                  }
                });
              },
              child: Text(isSelected ? 'ဖြုတ်မည်' : 'သုံးမည်'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final double amountToPay = _finalTotalAmount;
    final String transactionId = _selectedPaymentMethod == 'Cash on Delivery' 
        ? 'COD' 
        : _transactionController.text.trim();

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final paymentRef = firestore.collection('payments').doc();
      batch.set(paymentRef, {
        'paymentId': paymentRef.id,
        'requestId': widget.requestId ?? '',
        'serviceName': _serviceTitle,
        'customerId': user?.uid ?? '',
        'customerName': user?.displayName ?? user?.email ?? 'Customer',
        'amount': amountToPay,
        'originalAmount': (_materialCost + _serviceCost + _laborCost) > 0 ? (_materialCost + _serviceCost + _laborCost) : _baseTotalAmount,
        'discountAmount': _discountAmount,
        'paymentMethod': _selectedPaymentMethod,
        'transactionId': transactionId,
        'promoCode': _selectedPromoCode,
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (widget.requestId != null && widget.requestId!.isNotEmpty) {
        final requestRef = firestore.collection('service_requests').doc(widget.requestId);
        batch.update(requestRef, {
          'paymentStatus': 'pending',
          'paymentMethod': _selectedPaymentMethod,
          'transactionId': transactionId,
          'promoCode': _selectedPromoCode,
          'discountAmount': _discountAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (_selectedPromoCode != null && user != null) {
        final promoRef = firestore.collection('user_promos').doc();
        batch.set(promoRef, {
          'userId': user.uid,
          'requestId': widget.requestId ?? '',
          'promoCode': _selectedPromoCode,
          'usedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ငွေပေးချေမှု တင်သွင်းပြီးပါပြီ'),
          content: Text(
            'စုစုပေါင်း ငွေပမာဏ ${amountToPay.toStringAsFixed(0)} ကျပ် ($_selectedPaymentMethod) ဖြင့် ပေးချေရန် တင်သွင်းပြီးပါပြီ။ Admin အတည်ပြုချက်ကို စောင့်ဆိုင်းနေပါသည်။',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ရယူနိုင်သော Promocode များ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    _buildPromoListSection(),
                    const SizedBox(height: 20),

                    const Text(
                      'ငွေပေးချေမည့် နည်းလမ်း',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPaymentMethod = value);
                              }
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('KBZ Pay'),
                            value: 'KBZ Pay',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPaymentMethod = value);
                              }
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Wave Pay'),
                            value: 'Wave Pay',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPaymentMethod = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🌟 KBZ Pay သို့မဟုတ် Wave Pay ရွေးထားမှသာ ငွေလွှဲရမည့်အကောင့်အချက်အလက်နှင့် Transaction No. ပေါ်မည်
                    if (_selectedPaymentMethod != 'Cash on Delivery') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📌 $_selectedPaymentMethod ဖြင့် ငွေလွှဲရန် အချက်အလက်',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F4C5C),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('• Account No: 09974514299'),
                            const Text('• Account Name: Aye Nandar Kyaw'),
                            const SizedBox(height: 6),
                            const Text(
                              'အထက်ပါအကောင့်သို့ ငွေလွှဲပြီးပါက အောက်ပါကွက်လပ်တွင် Transaction No. ကို ထည့်သွင်းပေးပါ။',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$_selectedPaymentMethod Transaction No. ထည့်ရန်',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _transactionController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Transaction Number (ဥပမာ- ၂၁ သို့ ၂၂ လုံး)',
                          hintText: 'လွှဲပြောင်းထားသော Transaction No. ကို ထည့်ပါ',
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (_selectedPaymentMethod != 'Cash on Delivery') {
                            if (value == null || value.trim().isEmpty) {
                              return 'ကျေးဇူးပြု၍ Transaction No. ထည့်ပါ။';
                            }
                            if (value.trim().length < 15) {
                              return 'Transaction No. အချက်အလက် မမှန်ကန်ပါ။';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      'ငွေပေးချေရန် အသေးစိတ်',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
                              const Text('ဝန်ဆောင်မှု:'),
                              Flexible(
                                child: Text(
                                  _serviceTitle,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_materialCost > 0 || _serviceCost > 0 || _laborCost > 0) ...[
                            if (_materialCost > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ပစ္စည်းတန်ဖိုး (Material):'),
                                  Text('${_materialCost.toStringAsFixed(0)} ကျပ်'),
                                ],
                              ),
                            if (_serviceCost > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ဝန်ဆောင်ခ (Service):'),
                                  Text('${_serviceCost.toStringAsFixed(0)} ကျပ်'),
                                ],
                              ),
                            ],
                            if (_laborCost > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('လက်ခ (Labor):'),
                                  Text('${_laborCost.toStringAsFixed(0)} ကျပ်'),
                                ],
                              ),
                            ],
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ကျသင့်ငွေ:'),
                                Text('${_baseTotalAmount.toStringAsFixed(0)} ကျပ်'),
                              ],
                            ),
                          ],
                          if (_selectedPromoCode != null && _discountPercentage > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'လျှော့ငွေ ($_selectedPromoCode - ${_discountPercentage.toStringAsFixed(0)}%):',
                                ),
                                Text(
                                  '- ${_discountAmount.toStringAsFixed(0)} ကျပ်',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              const Text(
                                'စုစုပေါင်း ပေးချေရမည့်ငွေ:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_finalTotalAmount.toStringAsFixed(0)} ကျပ်',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF0F4C5C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

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
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ငွေပေးချေမှုကို အတည်ပြုမည်',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}