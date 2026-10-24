import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String collectionName; // 'users' သို့မဟုတ် 'technicians'
  final String userRole; // 'admin', 'technician', သို့မဟုတ် 'customer'

  const EditProfileScreen({
    super.key,
    required this.collectionName,
    required this.userRole,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _idNumberController;

  File? _selectedImageFile; // 🌟 ဖုန်းထဲမှ ရွေးချယ်ထားသော ပုံဖိုင်
  String _existingImageUrl = ''; // 🌟 Database ထဲတွင် ရှိပြီးသား ပုံလင့်ခ์ (သို့မဟုတ် Base64)

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _specializationController = TextEditingController();
    _idNumberController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection(widget.collectionName)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _nameController.text =
            data['name']?.toString() ??
            data['displayName']?.toString() ??
            user.displayName ??
            '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _specializationController.text =
            data['specialization']?.toString() ?? '';
        _idNumberController.text = data['idNumber']?.toString() ?? '';
        _existingImageUrl =
            data['profileImage']?.toString() ??
            data['profileImageUrl']?.toString() ??
            data['imageUrl']?.toString() ??
            '';
      } else {
        _nameController.text = user.displayName ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🖼️ Gallery မှ ပုံရွေးချယ်ရန် Function
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String imagePathToSave = _existingImageUrl;

      // အကယ်၍ ပုံအသစ်ရွေးထားပါက Local path သို့မဟုတ် Cloud Storage သို့ တင်ရန် (လောလောဆယ် path သို့မဟုတ် URL အဖြစ် သိမ်းမည်)
      if (_selectedImageFile != null) {
        // မှတ်ချက်: Firebase Storage အသုံးမပြုသေးပါက File path (သို့မဟုတ် base64) ကို သိမ်းနိုင်သည်
        imagePathToSave = _selectedImageFile!.path; 
      }

      final updatedData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'profileImage': imagePathToSave,
        'profileImageUrl': imagePathToSave,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.userRole.toLowerCase() == 'technician') {
        updatedData['specialization'] = _specializationController.text.trim();
      }

      await _firestore
          .collection(widget.collectionName)
          .doc(user.uid)
          .set(updatedData, SetOptions(merge: true));

      await user.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  IconData _getRoleIcon() {
    switch (widget.userRole.toLowerCase()) {
      case 'technician':
        return Icons.engineering;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.userRole.toUpperCase()} Profile Edit'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 🌟 ဓာတ်ပုံကို နှိပ်၍ Gallery မှ ရွေးချယ်နိုင်သော Widget
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (_existingImageUrl.isNotEmpty
                                    ? NetworkImage(_existingImageUrl)
                                        as ImageProvider
                                    : null),
                            child: (_selectedImageFile == null &&
                                    _existingImageUrl.isEmpty)
                                ? Icon(
                                    _getRoleIcon(),
                                    size: 50,
                                    color: Colors.blue.shade800,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'နာမည်ထည့်ရန် လိုအပ်ပါသည်။'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(
                        labelText: 'ID No. (မှတ်ပုံတင် / အလုပ်သမားအမှတ်)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    if (widget.userRole.toLowerCase() == 'technician') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specializationController,
                        decoration: const InputDecoration(
                          labelText: 'Specialization (e.g. AC, Plumbing)',
                          prefixIcon: Icon(Icons.build_outlined),
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
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