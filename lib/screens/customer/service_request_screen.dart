import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String categoryId;
  final String categoryName;
  final String description;
  final dynamic price;
  final String priceType;
  final int duration;

  const ServiceRequestScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.price,
    required this.priceType,
    required this.duration,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;

  bool _loading = false;
  bool _loadingProfile = true;

  String _savedTownship = '';
  String _savedCity = '';
  String _savedAddressNote = '';

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD SAVED PROFILE / ADDRESS
  // ============================================================

  Future<void> _loadSavedProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (!mounted) return;

      if (data != null) {
        final address = data['address']?.toString().trim() ?? '';
        final township = data['township']?.toString().trim() ?? '';
        final city = data['city']?.toString().trim() ?? '';
        final addressNote = data['addressNote']?.toString().trim() ?? '';
        final phone = data['phone']?.toString().trim() ?? '';

        setState(() {
          _addressController.text = address;
          _phoneController.text = phone;

          _savedTownship = township;
          _savedCity = city;
          _savedAddressNote = addressNote;

          _loadingProfile = false;
        });
      } else {
        setState(() {
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load saved address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CHANGE / ADD SAVED ADDRESS
  // ============================================================

  Future<void> _changeAddress() async {
    final result = await context.push('/customer/address');

    if (result == true) {
      await _loadSavedProfile();
    }
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice() {
    if (widget.priceType == 'quote') {
      return 'Quote';
    }

    final amount = widget.price is num
        ? widget.price.toDouble()
        : double.tryParse(widget.price?.toString() ?? '') ?? 0;

    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );

    if (widget.priceType == 'starting_from') {
      return 'From $formatted MMK';
    }

    return '$formatted MMK';
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (selected != null) {
      setState(() {
        _preferredDate = selected;
      });
    }
  }

  // ============================================================
  // SELECT TIME
  // ============================================================

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selected != null) {
      setState(() {
        _preferredTime = selected;
      });
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // ADDRESS PREVIEW
  // ============================================================

  String _getFullAddressPreview() {
    final address = _addressController.text.trim();

    final parts = [
      address,
      _savedTownship,
      _savedCity,
    ].where((value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  // ============================================================
  // SAVED ADDRESS CARD
  // ============================================================

  Widget _buildSavedAddressCard() {
    final address = _addressController.text.trim();

    final hasSavedAddress =
        address.isNotEmpty ||
        _savedTownship.isNotEmpty ||
        _savedCity.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSavedAddress
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFFCD34D),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Service Address',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (hasSavedAddress) ...[
            Text(
              _getFullAddressPreview(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),

            if (_savedAddressNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 17,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _savedAddressNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _changeAddress,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Change Address'),
              ),
            ),
          ] else ...[
            const Text(
              'You have not saved a service address yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _changeAddress,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add Saved Address'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT REQUEST
  // ============================================================

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select preferred date.')),
      );
      return;
    }

    if (_preferredTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select preferred time.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first.')));
      return;
    }

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your service address.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('service_requests')
          .doc();

      await requestRef.set({
        'requestId': requestRef.id,

        // ======================================================
        // CUSTOMER
        // ======================================================
        'customerId': user.uid,
        'customerEmail': user.email ?? '',

        // ======================================================
        // SERVICE
        // ======================================================
        'serviceId': widget.serviceId,
        'serviceName': widget.serviceName,
        'categoryId': widget.categoryId,
        'categoryName': widget.categoryName,
        'serviceDescription': widget.description,

        'price': widget.price,
        'priceType': widget.priceType,

        // ======================================================
        // CUSTOMER PROBLEM
        // ======================================================
        'customerDescription': _descriptionController.text.trim(),

        // ======================================================
        // SERVICE ADDRESS
        // ======================================================
        'address': address,
        'township': _savedTownship,
        'city': _savedCity,
        'addressNote': _savedAddressNote,

        // ======================================================
        // CONTACT
        // ======================================================
        'phone': phone,

        // ======================================================
        // PREFERRED DATE
        // ======================================================
        'preferredDate': Timestamp.fromDate(_preferredDate!),

        // ======================================================
        // PREFERRED TIME
        // ======================================================
        'preferredTime':
            '${_preferredTime!.hour.toString().padLeft(2, '0')}:'
            '${_preferredTime!.minute.toString().padLeft(2, '0')}',

        // ======================================================
        // STATUS
        // ======================================================
        'status': 'pending',

        // ======================================================
        // TECHNICIAN
        // ======================================================
        'technicianId': null,
        'technicianName': null,

        // ======================================================
        // QUOTATION
        // ======================================================
        'quotationId': null,

        // ======================================================
        // PAYMENT
        // ======================================================
        'paymentStatus': 'unpaid',

        // ======================================================
        // TIMESTAMP
        // ======================================================
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/customer');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
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
      appBar: AppBar(
        title: const Text(
          'Request Service',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ==================================================
                  // SERVICE CARD
                  // ==================================================

                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.serviceName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.categoryName,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            _formatPrice(),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          if (widget.duration > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 17),
                                const SizedBox(width: 5),
                                Text('Estimated ${widget.duration} min'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SERVICE DETAILS
                  // ==================================================
                  const Text(
                    'Service Details',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Describe your problem',
                      hintText: 'Please describe the repair problem...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your problem.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // PHONE
                  // ==================================================
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '09xxxxxxxxx',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SAVED ADDRESS
                  // ==================================================
                  _buildSavedAddressCard(),

                  const SizedBox(height: 16),

                  // ==================================================
                  // ADDRESS EDIT FIELD
                  // ==================================================
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Service Address',
                      hintText: 'Enter the address where service is needed...',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter service address.';
                      }

                      return null;
                    },
                  ),

                  // ==================================================
                  // TOWNSHIP / CITY PREVIEW
                  // ==================================================
                  if (_savedTownship.isNotEmpty || _savedCity.isNotEmpty) ...[
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [
                                if (_savedTownship.isNotEmpty) _savedTownship,
                                if (_savedCity.isNotEmpty) _savedCity,
                              ].join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ==================================================
                  // DATE & TIME
                  // ==================================================
                  const Text(
                    'Preferred Date & Time',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _preferredDate == null
                                ? 'Select Date'
                                : _formatDate(_preferredDate!),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _selectTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _preferredTime == null
                                ? 'Select Time'
                                : _preferredTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // SUBMIT
                  // ==================================================
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitRequest,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Service Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  String selectedEmergencyType =
      "ရေပိုက် အကြီးစားပေါက်ခြင်း (Water Pipe Burst)";

  final List<String> emergencyTypes = [
    "ရေပိုက် အကြီးစားပေါက်ခြင်း (Water Pipe Burst)",
    "လျှပ်စစ် မီးပွားထွက်/ဝိုင်ယာရှော့ဖြစ်ခြင်း (Electrical Short Circuit)",
    "အဓိက မီးခလုတ်ဘောက်စ် ပျက်စီးခြင်း (Main Breaker Failure)",
    "အခြား အရေးပေါ် ပြဿနာ (Other Emergency)",
  ];

  bool isSendingAlert = false;

  void _triggerSosAlert() {
    setState(() {
      isSendingAlert = true;
    });

    // အရေးပေါ် အချက်ပြမှုကို Admin ထံ ပို့ဆောင်ခြင်း simulation
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isSendingAlert = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text("အရေးပေါ် အကြောင်းကြားပြီးပါပြီ"),
              ],
            ),
            content: const Text(
              "သင်၏ အရေးပေါ် တောင်းဆိုမှုကို Admin နှင့် အနီးဆုံး ကျွမ်းကျင်ဆရာများထံသို့ ပေးပို့လိုက်ပါပြီ။ ဆရာမှ ၁ မိနစ်အတွင်း ပြန်လည် ဆက်သွယ်ပါမည်။",
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Home Screen သို့ ပြန်သွားရန်
                },
                child: const Text(
                  "ကောင်းပါပြီ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("အရေးပေါ် အကူအညီ (SOS Fast-Booking)"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "အရေးပေါ် အခြေအနေ သတိပေးချက်",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "ဤစနစ်သည် အိမ်တွင်း အရေးပေါ် ပျက်စီးမှုများအတွက် Admin ထံသို့ ဦးစားပေး အမြန်ဆုံး (Fast-Booking) တင်ပေးသော စနစ် ဖြစ်ပါသည်။",
                          style: TextStyle(color: Colors.black87, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "ကြုံတွေ့နေရသော အရေးပေါ် ပြဿနာ အမျိုးအစား",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // အရေးပေါ် အမျိုးအစားများ ရွေးချယ်ရန်
            ...emergencyTypes.map((type) {
              return RadioListTile<String>(
                title: Text(type, style: const TextStyle(fontSize: 14)),
                value: type,
                groupValue: selectedEmergencyType,
                activeColor: Colors.red,
                onChanged: (String? value) {
                  setState(() {
                    selectedEmergencyType = value!;
                  });
                },
              );
            }),

            const SizedBox(height: 20),
            const Text(
              "လက်ရှိ တည်နေရာ (Current GPS Location)",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "အမှတ် (၁၂၃)၊ ကမာရွတ်လမ်း၊ ကမာရွတ်မြို့နယ်၊ ရန်ကုန်မြို့။",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // အရေးပေါ် ခလုတ်ကြီး (SOS Trigger Button)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isSendingAlert ? null : _triggerSosAlert,
                child: isSendingAlert
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "🚨 အရေးပေါ် ဆရာခေါ်မည် (SOS EMERGENCY)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleMaintenanceScreen extends StatefulWidget {
  const ScheduleMaintenanceScreen({super.key});

  @override
  State<ScheduleMaintenanceScreen> createState() =>
      _ScheduleMaintenanceScreenState();
}

class _ScheduleMaintenanceScreenState extends State<ScheduleMaintenanceScreen> {
  String selectedService = "အဲကွန်း ပုံမှန်ဆေးကြောခြင်း (Aircon Maintenance)";
  String selectedInterval = "၃ လ တစ်ကြိမ် (Every 3 Months)";

  final List<String> maintenanceServices = [
    "အဲကွန်း ပုံမှန်ဆေးကြောခြင်း (Aircon Maintenance)",
    "ရေပိုက်လိုင်း စစ်ဆေးခြင်း (Plumbing Checkup)",
    "လျှပ်စစ် မီးပလပ်နှင့် ဘောက်စ်စစ်ဆေးခြင်း (Electrical Checkup)",
  ];

  final List<String> intervals = [
    "၁ လ တစ်ကြိမ် (Monthly)",
    "၃ လ တစ်ကြိမ် (Every 3 Months)",
    "၆ လ တစ်ကြိမ် (Every 6 Months)",
  ];

  bool isVipMember = false;

  void _subscribeMaintenance() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.blue),
              SizedBox(width: 8),
              Text("Subscription အောင်မြင်ပါသည်"),
            ],
          ),
          content: Text(
            "သတ်မှတ်ထားသော အချိန်ရောက်တိုင်း '$selectedService' အတွက် အလိုအလျောက် သတိပေးချက် (Reminder) ပေးမည်ဖြစ်ပြီး VIP အကျိုးခံစားခွင့်များ ရရှိမည်ဖြစ်ပါသည်။",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                "ကျေးဇူးတင်ပါတယ်",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ပုံမှန် ပြုပြင်ထိန်းသိမ်းမှုနှင့် အသင်းဝင်စနစ်"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VIP Membership Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orangeAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "VIP အသင်းဝင် Package",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "လစဉ်ကြေးဖြင့် လာရောက်ခ အခမဲ့၊ ၁၀% Discount နှင့် အရေးပေါ် ဦးစားပေး Fast-Booking များ ရယူလိုက်ပါ။",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "ပုံမှန်ပြုပြင်ရန် ဝန်ဆောင်မှု ရွေးချယ်ပါ",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedService,
                  isExpanded: true,
                  items: maintenanceServices.map((String service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedService = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "ပြုလုပ်မည့် ကြိမ်နှုန်း (Interval)",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedInterval,
                  isExpanded: true,
                  items: intervals.map((String interval) {
                    return DropdownMenuItem<String>(
                      value: interval,
                      child: Text(interval),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedInterval = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            CheckboxListTile(
              title: const Text(
                "VIP အသင်းဝင်စနစ်ပါ တစ်ပါတည်း ရယူမည် (လစဉ် ၁၀,၀၀၀ ကျပ်)",
              ),
              value: isVipMember,
              activeColor: Colors.blueAccent,
              onChanged: (bool? value) {
                setState(() {
                  isVipMember = value ?? false;
                });
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _subscribeMaintenance,
                child: const Text(
                  "Subscription အတည်ပြုမည်",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
