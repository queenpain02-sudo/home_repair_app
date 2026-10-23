import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerAddressScreen extends StatefulWidget {
  const CustomerAddressScreen({super.key});

  @override
  State<CustomerAddressScreen> createState() => _CustomerAddressScreenState();
}

class _CustomerAddressScreenState extends State<CustomerAddressScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color darkColor = Color(0xFF0F172A);
  static const Color backgroundColor = Color(0xFFF6F8FC);

  CollectionReference<Map<String, dynamic>> get _addresses {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('addresses');
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    return _firestore.collection('users').doc(_auth.currentUser!.uid);
  }

  @override
  void initState() {
    super.initState();

    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
  }

  Future<void> _showAddressForm({
    String? addressId,
    Map<String, dynamic>? initialData,
  }) async {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController(
      text: initialData?['address']?.toString() ?? '',
    );
    final townshipController = TextEditingController(
      text: initialData?['township']?.toString() ?? '',
    );
    final cityController = TextEditingController(
      text: initialData?['city']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: initialData?['addressNote']?.toString() ?? '',
    );

    String category = initialData?['category']?.toString() ?? 'Home';
    bool isDefault = initialData?['isDefault'] == true;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                addressId == null ? 'Add Address' : 'Edit Address',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: darkColor,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Address Category',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Home',
                              child: Text('🏠 Home / အိမ်'),
                            ),
                            DropdownMenuItem(
                              value: 'Work',
                              child: Text('💼 Work / အလုပ်'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('📍 Other / အခြား'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => category = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Home Address',
                            hintText: 'House number, street, building',
                            prefixIcon: Icon(Icons.home_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter your address'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: townshipController,
                          decoration: const InputDecoration(
                            labelText: 'Township',
                            prefixIcon: Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter township'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.apartment_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter city'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Additional Note (Optional)',
                            hintText: 'Landmark, floor, gate color...',
                            prefixIcon: Icon(Icons.notes_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isDefault,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Set as default address',
                            style: TextStyle(fontSize: 13),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              isDefault = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            final batch = _firestore.batch();
                            final collection = _addresses;
                            final userRef = _userDoc;

                            final cleanAddress = addressController.text.trim();
                            final cleanTownship = townshipController.text.trim();
                            final cleanCity = cityController.text.trim();
                            final cleanNote = noteController.text.trim();

                            final existing = await collection.get();

                            // ပထမဆုံးထည့်သည့် လိပ်စာဖြစ်ပါက အလိုအလျောက် Default သတ်မှတ်မည်
                            bool makeDefault = isDefault;
                            if (!makeDefault && existing.docs.isEmpty) {
                              makeDefault = true;
                            }

                            if (makeDefault) {
                              for (final doc in existing.docs) {
                                if (doc.id != addressId &&
                                    doc.data()['isDefault'] == true) {
                                  batch.update(doc.reference, {
                                    'isDefault': false,
                                  });
                                }
                              }
                            }

                            final data = <String, dynamic>{
                              'category': category,
                              'address': cleanAddress,
                              'township': cleanTownship,
                              'city': cleanCity,
                              'addressNote': cleanNote,
                              'isDefault': makeDefault,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            String targetAddressId;

                            if (addressId == null) {
                              final newRef = collection.doc();
                              targetAddressId = newRef.id;
                              data['createdAt'] = FieldValue.serverTimestamp();
                              batch.set(newRef, data);
                            } else {
                              targetAddressId = addressId;
                              batch.update(collection.doc(addressId), data);
                            }

                            // Default ဖြစ်ပါက ပင်မ user document ထဲသို့ပါ လိပ်စာအချက်အလက်များ ထည့်သွင်းမည်
                            if (makeDefault) {
                              batch.set(userRef, {
                                'defaultAddressId': targetAddressId,
                                'address': cleanAddress,
                                'township': cleanTownship,
                                'city': cleanCity,
                                'addressNote': cleanNote,
                                'addressCategory': category,
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                            } else {
                              final userSnapshot = await userRef.get();
                              final currentDefaultId =
                                  userSnapshot.data()?['defaultAddressId'];

                              if (currentDefaultId == null ||
                                  currentDefaultId == targetAddressId) {
                                batch.set(userRef, {
                                  'defaultAddressId': targetAddressId,
                                  'address': cleanAddress,
                                  'township': cleanTownship,
                                  'city': cleanCity,
                                  'addressNote': cleanNote,
                                  'addressCategory': category,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                              }
                            }

                            await batch.commit();

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Unable to save address: $e'),
                                backgroundColor: Colors.red.shade600,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Address'),
                ),
              ],
            );
          },
        );
      },
    );

    addressController.dispose();
    townshipController.dispose();
    cityController.dispose();
    noteController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully')),
      );
    }
  }

  Future<void> _setDefault(String addressId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _addresses.get();
      Map<String, dynamic>? selectedData;

      for (final doc in snapshot.docs) {
        final isSelected = doc.id == addressId;
        batch.update(doc.reference, {'isDefault': isSelected});
        if (isSelected) {
          selectedData = doc.data();
        }
      }

      batch.set(_userDoc, {
        'defaultAddressId': addressId,
        'address': selectedData?['address'] ?? '',
        'township': selectedData?['township'] ?? '',
        'city': selectedData?['city'] ?? '',
        'addressNote': selectedData?['addressNote'] ?? '',
        'addressCategory': selectedData?['category'] ?? 'Home',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Default address updated')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update default address: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _deleteAddress(
    String addressId,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text(
          'Are you sure you want to delete this saved address?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = _firestore.batch();
      batch.delete(_addresses.doc(addressId));

      final userSnapshot = await _userDoc.get();
      final currentDefault = userSnapshot.data()?['defaultAddressId'];

      if (currentDefault == addressId || data['isDefault'] == true) {
        final remaining = await _addresses.get();

        final nextAddress = remaining.docs
            .where((doc) => doc.id != addressId)
            .firstOrNull;

        if (nextAddress != null) {
          final nextData = nextAddress.data();
          batch.update(nextAddress.reference, {'isDefault': true});
          batch.set(_userDoc, {
            'defaultAddressId': nextAddress.id,
            'address': nextData['address'] ?? '',
            'township': nextData['township'] ?? '',
            'city': nextData['city'] ?? '',
            'addressNote': nextData['addressNote'] ?? '',
            'addressCategory': nextData['category'] ?? 'Home',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          batch.set(_userDoc, {
            'defaultAddressId': FieldValue.delete(),
            'address': FieldValue.delete(),
            'township': FieldValue.delete(),
            'city': FieldValue.delete(),
            'addressNote': FieldValue.delete(),
            'addressCategory': FieldValue.delete(),
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Address deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete address: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Home':
        return Icons.home_rounded;
      case 'Work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'Home':
        return 'အိမ်';
      case 'Work':
        return 'အလုပ်';
      default:
        return 'အခြား';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(true),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkColor),
        ),
        title: const Text(
          'My Addresses',
          style: TextStyle(color: darkColor, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Address'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _addresses.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load addresses. Please try again.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final docs = snapshot.data?.docs.toList() ?? [];

          docs.sort((a, b) {
            final aDefault = a.data()['isDefault'] == true;
            final bDefault = b.data()['isDefault'] == true;

            if (aDefault == bDefault) return 0;
            return aDefault ? -1 : 1;
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Service Addresses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Save home, work and other addresses for faster booking.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 55,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No saved addresses yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap Add Address to save your first address.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ...docs.map((doc) {
                final data = doc.data();
                final category = data['category']?.toString() ?? 'Other';
                final isDefault = data['isDefault'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDefault ? primaryColor : const Color(0xFFE2E8F0),
                      width: isDefault ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _categoryIcon(category),
                              color: primaryColor,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_categoryLabel(category)} ($category)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: darkColor,
                                  ),
                                ),
                                if (isDefault)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      'DEFAULT ADDRESS',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showAddressForm(
                                  addressId: doc.id,
                                  initialData: data,
                                );
                              } else if (value == 'delete') {
                                _deleteAddress(doc.id, data);
                              } else if (value == 'default') {
                                _setDefault(doc.id);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isDefault)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Set as Default'),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Address'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Address'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data['address']?.toString() ?? '',
                        style: const TextStyle(
                          color: darkColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${data['township'] ?? ''}, ${data['city'] ?? ''}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      if ((data['addressNote']?.toString() ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Note: ${data['addressNote']}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (!isDefault) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _setDefault(doc.id),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Make Default'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}