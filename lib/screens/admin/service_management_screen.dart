import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loadingCategories = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ============================================================
  // LOAD CATEGORIES
  // ============================================================
 Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('service_categories').get();

      final List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'id': doc.id.toString(),
          'name': data['name']?.toString() ?? 'Category',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load categories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ============================================================
  // ADD / EDIT SERVICE DIALOG
  // ============================================================
  Future<void> _showServiceDialog({
    DocumentSnapshot<Map<String, dynamic>>? serviceDoc,
  }) async {
    final data = serviceDoc?.data();

    final nameController = TextEditingController(
      text: data?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: data?['description']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: data?['price']?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: data?['duration']?.toString() ?? '30',
    );

    String? selectedCategoryId = data?['categoryId']?.toString();

    // 🛡️ Dropdown Value Mismatch မှ ကာကွယ်ရန်
    if (selectedCategoryId != null &&
        !_categories.any((cat) => cat['id'] == selectedCategoryId)) {
      selectedCategoryId = null;
    }

    String selectedPriceType = data?['priceType']?.toString() ?? 'fixed';
    bool isActive = data?['isActive'] as bool? ?? true;

    final formKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(serviceDoc == null ? 'Add Service' : 'Edit Service'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Service Name
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Service Name',
                            prefixIcon: Icon(Icons.build_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter service name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['id'] as String,
                              child: Text(category['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Price
                        TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Price (MMK)',
                            prefixIcon: Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter price';
                            }
                            final price = double.tryParse(value.trim());
                            if (price == null || price < 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Price Type
                        DropdownButtonFormField<String>(
                          initialValue: selectedPriceType,
                          decoration: const InputDecoration(
                            labelText: 'Price Type',
                            prefixIcon: Icon(Icons.price_check_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'fixed',
                              child: Text('Fixed Price'),
                            ),
                            DropdownMenuItem(
                              value: 'starting_from',
                              child: Text('Starting From'),
                            ),
                            DropdownMenuItem(
                              value: 'quote',
                              child: Text('Get a Quote'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedPriceType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Estimated Duration
                        TextFormField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Estimated Duration (minutes)',
                            prefixIcon: Icon(Icons.timer_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter duration';
                            }
                            final duration = int.tryParse(value.trim());
                            if (duration == null || duration <= 0) {
                              return 'Please enter valid duration';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Active Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          subtitle: const Text(
                            'Customers can see this service',
                          ),
                          value: isActive,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
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
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
              FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a valid category'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final selectedCatMap = _categories.firstWhere(
                        (item) => item['id'] == selectedCategoryId,
                        orElse: () => <String, dynamic>{'id': '', 'name': 'Service'},
                      );

                      final price = double.parse(priceController.text.trim());
                      final duration = int.parse(
                        durationController.text.trim(),
                      );

                      final serviceData = <String, dynamic>{
                        'name': nameController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'categoryId': selectedCategoryId!,
                        'categoryName': selectedCatMap['name'] ?? 'Service',
                        'price': price,
                        'priceType': selectedPriceType,
                        'duration': duration,
                        'isActive': isActive,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (serviceDoc == null) {
                        serviceData['createdAt'] = FieldValue.serverTimestamp();
                        serviceData['sortOrder'] = 0;
                        await _firestore
                            .collection('services')
                            .add(serviceData);
                      } else {
                        await _firestore
                            .collection('services')
                            .doc(serviceDoc.id)
                            .update(serviceData);
                      }

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      print('===== ERROR SAVING SERVICE: $e =====');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save service: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    serviceDoc == null ? 'Add Service' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    durationController.dispose();
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================
  Future<void> _deleteService(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final name = data?['name']?.toString() ?? 'ရှင့်ဝန်ဆောင်မှု';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('services').doc(doc.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0';
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  String _priceLabel(dynamic price, String priceType) {
    final formatted = _formatPrice(price);
    switch (priceType) {
      case 'starting_from':
        return 'From $formatted MMK';
      case 'quote':
        return 'Quote';
      default:
        return '$formatted MMK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingCategories ? null : () => _showServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load services.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No services yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Tap "Add Service" to create your first service.'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final name = data['name']?.toString() ?? '';
                    final categoryName =
                        data['categoryName']?.toString() ?? 'Unknown Category';
                    final description = data['description']?.toString() ?? '';
                    final price = data['price'];
                    final priceType = data['priceType']?.toString() ?? 'fixed';
                    final duration = data['duration'];
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.build_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _priceLabel(price, priceType),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (duration != null) ...[
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$duration min',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showServiceDialog(serviceDoc: doc);
                            }
                            if (value == 'delete') {
                              _deleteService(doc);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
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