import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdvertisementManagementScreen extends StatefulWidget {
  const AdvertisementManagementScreen({super.key});

  @override
  State<AdvertisementManagementScreen> createState() =>
      _AdvertisementManagementScreenState();
}

class _AdvertisementManagementScreenState
    extends State<AdvertisementManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color primaryColor = const Color(0xFF2563EB);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color darkColor = const Color(0xFF0F172A);

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // ADD / EDIT DIALOG
  // ============================================================

  Future<void> _showAdvertisementDialog({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final data = document?.data();

    final titleController = TextEditingController(
      text: data?['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: data?['description']?.toString() ?? '',
    );

    final imageUrlController = TextEditingController(
      text: data?['imageUrl']?.toString() ?? '',
    );

    final buttonTextController = TextEditingController(
      text: data?['buttonText']?.toString() ?? 'Book Now',
    );

    final serviceIdController = TextEditingController(
      text: data?['serviceId']?.toString() ?? '',
    );

    final categoryIdController = TextEditingController(
      text: data?['categoryId']?.toString() ?? '',
    );

    final displayOrderController = TextEditingController(
      text: data?['displayOrder']?.toString() ?? '0',
    );

    bool active = data?['active'] == true;

    DateTime? startDate;

    DateTime? endDate;

    final startTimestamp = data?['startDate'];

    final endTimestamp = data?['endDate'];

    if (startTimestamp is Timestamp) {
      startDate = startTimestamp.toDate();
    }

    if (endTimestamp is Timestamp) {
      endDate = endTimestamp.toDate();
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                document == null ? 'Add Advertisement' : 'Edit Advertisement',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // TITLE
                      // ==================================================

                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Advertisement Title',
                          hintText: 'e.g. Home Repair Special Offer',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Advertisement description',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // IMAGE URL
                      // ==================================================
                      TextField(
                        controller: imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://...',
                          prefixIcon: const Icon(Icons.image_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // BUTTON TEXT
                      // ==================================================
                      TextField(
                        controller: buttonTextController,
                        decoration: InputDecoration(
                          labelText: 'Button Text',
                          hintText: 'Book Now',
                          prefixIcon: const Icon(Icons.smart_button_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // SERVICE ID
                      // ==================================================
                      TextField(
                        controller: serviceIdController,
                        decoration: InputDecoration(
                          labelText: 'Service ID (Optional)',
                          hintText: 'Leave empty if not linked',
                          prefixIcon: const Icon(
                            Icons.home_repair_service_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // CATEGORY ID
                      // ==================================================
                      TextField(
                        controller: categoryIdController,
                        decoration: InputDecoration(
                          labelText: 'Category ID (Optional)',
                          hintText: 'Leave empty if not linked',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // DISPLAY ORDER
                      // ==================================================
                      TextField(
                        controller: displayOrderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Display Order',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.sort),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // ACTIVE
                      // ==================================================
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active Advertisement',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Show this advertisement to customers',
                        ),
                        value: active,
                        activeThumbColor: primaryColor,
                        onChanged: (value) {
                          setDialogState(() {
                            active = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // START DATE
                      // ==================================================
                      _buildDatePickerTile(
                        title: 'Start Date',
                        date: startDate,
                        icon: Icons.calendar_today_outlined,
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (selected != null) {
                            setDialogState(() {
                              startDate = selected;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // END DATE
                      // ==================================================
                      _buildDatePickerTile(
                        title: 'End Date',
                        date: endDate,
                        icon: Icons.event_available_outlined,
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (selected != null) {
                            setDialogState(() {
                              endDate = selected;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter advertisement title.'),
                        ),
                      );
                      return;
                    }

                    final displayOrder =
                        int.tryParse(displayOrderController.text.trim()) ?? 0;

                    if (startDate != null &&
                        endDate != null &&
                        endDate!.isBefore(startDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'End date cannot be before start date.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final collection = _firestore.collection(
                        'advertisements',
                      );

                      final advertisementRef =
                          document?.reference ?? collection.doc();

                      final advertisementId = advertisementRef.id;

                      final serviceId = serviceIdController.text.trim();

                      final categoryId = categoryIdController.text.trim();

                      final dataToSave = <String, dynamic>{
                        'advertisementId': advertisementId,
                        'title': title,
                        'description': descriptionController.text.trim(),
                        'imageUrl': imageUrlController.text.trim(),
                        'buttonText': buttonTextController.text.trim().isEmpty
                            ? 'Book Now'
                            : buttonTextController.text.trim(),
                        'serviceId': serviceId.isEmpty ? null : serviceId,
                        'categoryId': categoryId.isEmpty ? null : categoryId,
                        'active': active,
                        'displayOrder': displayOrder,
                        'startDate': startDate == null
                            ? null
                            : Timestamp.fromDate(startDate!),
                        'endDate': endDate == null
                            ? null
                            : Timestamp.fromDate(endDate!),
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (document == null) {
                        dataToSave['createdAt'] = FieldValue.serverTimestamp();
                      }

                      await advertisementRef.set(
                        dataToSave,
                        SetOptions(merge: true),
                      );

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            document == null
                                ? 'Advertisement added successfully.'
                                : 'Advertisement updated successfully.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save advertisement: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    document == null ? 'Add Advertisement' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    buttonTextController.dispose();
    serviceIdController.dispose();
    categoryIdController.dispose();
    displayOrderController.dispose();
  }

  // ============================================================
  // DATE PICKER TILE
  // ============================================================

  Widget _buildDatePickerTile({
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date == null
                        ? 'Not selected'
                        : '${date.day.toString().padLeft(2, '0')}/'
                              '${date.month.toString().padLeft(2, '0')}/'
                              '${date.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAdvertisement(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    final title = data?['title']?.toString() ?? 'Advertisement';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Advertisement',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await document.reference.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advertisement deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete advertisement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================

  Future<void> _toggleActive(
    DocumentSnapshot<Map<String, dynamic>> document,
    bool value,
  ) async {
    try {
      await document.reference.update({
        'active': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ADVERTISEMENT CARD
  // ============================================================

  Widget _buildAdvertisementCard(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final title = data['title']?.toString() ?? 'Untitled';

    final description = data['description']?.toString() ?? '';

    final imageUrl = data['imageUrl']?.toString() ?? '';

    final buttonText = data['buttonText']?.toString() ?? 'Book Now';

    final active = data['active'] == true;

    final displayOrder = (data['displayOrder'] as num?)?.toInt() ?? 0;

    final startTimestamp = data['startDate'] is Timestamp
        ? data['startDate'] as Timestamp
        : null;

    final endTimestamp = data['endDate'] is Timestamp
        ? data['endDate'] as Timestamp
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 95,
                    height: 95,
                    color: const Color(0xFFF1F5F9),
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.image_outlined,
                            size: 36,
                            color: Colors.grey,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image_outlined,
                                size: 36,
                                color: Colors.grey,
                              );
                            },
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // ==================================================
                // DETAILS
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.green.withValues(alpha: 0.10)
                                  : Colors.grey.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.smart_button_outlined,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            buttonText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ======================================================
            // DATE / ORDER
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _buildSmallInfo(Icons.sort, 'Order', '$displayOrder'),
                  _buildSmallInfo(
                    Icons.calendar_today_outlined,
                    'Start',
                    _formatDate(startTimestamp),
                  ),
                  _buildSmallInfo(
                    Icons.event_available_outlined,
                    'End',
                    _formatDate(endTimestamp),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ======================================================
            // ACTIONS
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Switch(
                        value: active,
                        activeThumbColor: primaryColor,
                        onChanged: (value) {
                          _toggleActive(document, value);
                        },
                      ),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    _showAdvertisementDialog(document: document);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',
                  onPressed: () {
                    _deleteAdvertisement(document);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL INFO
  // ============================================================

  Widget _buildSmallInfo(IconData icon, String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Text(
          '$title: ',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Advertisements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),

      // ==========================================================
      // ADD BUTTON
      // ==========================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          _showAdvertisementDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Advertisement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('advertisements')
            .orderBy('displayOrder')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load advertisements.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 45,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'No Advertisements Yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Create your first advertisement for customers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () {
                        _showAdvertisementDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Advertisement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return _buildAdvertisementCard(documents[index]);
            },
          );
        },
      ),
    );
  }
}
