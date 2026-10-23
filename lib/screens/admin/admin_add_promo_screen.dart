import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAddPromoScreen extends StatefulWidget {
  const AdminAddPromoScreen({super.key});

  @override
  State<AdminAddPromoScreen> createState() => _AdminAddPromoScreenState();
}

class _AdminAddPromoScreenState extends State<AdminAddPromoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  // Firestore ထဲသို့ Promocode အသစ် ထည့်သွင်းခြင်း
  Future<void> _createPromoCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String code = _codeController.text.trim().toUpperCase();
      double discount = double.parse(_discountController.text.trim());
      String description = _descController.text.trim();

      // 'promocodes' collection ထဲသို့ Document ID ကို code အမည်ဖြင့် တိုက်ရိုက်သိမ်းမည်
      await FirebaseFirestore.instance.collection('promocodes').doc(code).set({
        'code': code,
        'discount': discount,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promocode အသစ် ထည့်သွင်းပြီးပါပြီ။'), backgroundColor: Colors.green),
      );

      // Form ကို ရှင်းလင်းမည်
      _codeController.clear();
      _discountController.clear();
      _descController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Promocode ဖန်တီးရန်'),
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1️⃣ Promo Code အမည် (ဥပမာ - LABOR10)
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Promocode (ဥပမာ - LABOR10)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'ကုဒ်ထည့်ရန် လိုအပ်ပါသည်။' : null,
              ),
              const SizedBox(height: 16),

              // 2️⃣ လျှော့မည့် ရာခိုင်နှုန်း (ဥပမာ - 10)
              TextFormField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'လျှော့မည့် ရာခိုင်နှုန်း (%) (ဥပမာ - 10)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'ရာခိုင်နှုန်း ထည့်ရန် လိုအပ်ပါသည်။';
                  if (double.tryParse(value) == null) return 'ဂဏန်းသာ ထည့်ပါ။';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3️⃣ ဖော်ပြချက် (Description)
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'ဖော်ပြချက် (ဥပမာ - လက်ခအတွက် ၁၀% လျှော့စျေး)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'ဖော်ပြချက် ထည့်ရန် လိုအပ်ပါသည်။' : null,
              ),
              const SizedBox(height: 30),

              // 4️⃣ Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _createPromoCode,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Promocode သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}