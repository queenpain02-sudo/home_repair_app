import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF7F8FA);
  static const Color _text = Color(0xFF172033);
  static const Color _muted = Color(0xFF788397);
  static const Color _border = Color(0xFFEAEDF2);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _userData = null;
        _loading = false;
      });
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();
      final mergedData = Map<String, dynamic>.from(doc.data() ?? {});

      // addresses subcollection ထဲမှ Default လိပ်စာကို လှမ်းယူခြင်း
      final addressesSnapshot = await userRef.collection('addresses').get();

      if (addressesSnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot<Map<String, dynamic>>? defaultDoc;
        final defaultAddressId = mergedData['defaultAddressId']?.toString();

        if (defaultAddressId != null && defaultAddressId.isNotEmpty) {
          for (final addrDoc in addressesSnapshot.docs) {
            if (addrDoc.id == defaultAddressId) {
              defaultDoc = addrDoc;
              break;
            }
          }
        }

        defaultDoc ??= addressesSnapshot.docs
                .where((d) => d.data()['isDefault'] == true)
                .firstOrNull ??
            addressesSnapshot.docs.first;

        final addrData = defaultDoc.data();
        mergedData['address'] = addrData['address'] ?? '';
        mergedData['township'] = addrData['township'] ?? '';
        mergedData['city'] = addrData['city'] ?? '';
      }

      if (!mounted) return;

      setState(() {
        _userData = mergedData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile ဖတ်၍မရပါ: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _getString(String key) {
    return _userData?[key]?.toString().trim() ?? '';
  }

  String get _name {
    final name = _getString('name');
    if (name.isNotEmpty) return name;

    final displayName = _getString('displayName');
    if (displayName.isNotEmpty) return displayName;

    return _auth.currentUser?.displayName ?? 'Customer';
  }

  String get _email {
    final email = _getString('email');
    return email.isNotEmpty ? email : (_auth.currentUser?.email ?? '');
  }

  String get _phone => _getString('phone');

  String get _role {
    final role = _getString('role');
    return role.isEmpty ? 'Customer' : role;
  }

  String get _fullAddress {
    return [
      _getString('address'),
      _getString('township'),
      _getString('city'),
    ].where((value) => value.isNotEmpty).join(', ');
  }
  
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Logout'),
          content: const Text('သင့်အကောင့်မှ ထွက်ရန် သေချာပါသလား။'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await _auth.signOut();

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout မအောင်မြင်ပါ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAvatar({double size = 76}) {
    final user = _auth.currentUser;

    final imageUrl = _getString('profileImageUrl').isNotEmpty
        ? _getString('profileImageUrl')
        : (user?.photoURL ?? '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person_rounded, size: 40, color: _primary),
              )
            : const Icon(Icons.person_rounded, size: 40, color: _primary),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12, top: 22),
      child: Text(
        title,
        style: const TextStyle(
          color: _text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _muted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'မဖြည့်ရသေးပါ' : value,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = _primary,
    bool destructive = false,
    bool showArrow = true,
  }) {
    final color = destructive ? Colors.red : iconColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: destructive ? Colors.red : _text,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        trailing: showArrow
            ? const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8C5))
            : null,
      ),
    );
  }

  Future<void> _openRoute(String route) async {
    await context.push(route);

    if (!mounted) return;

    // ရှေ့မျက်နှာပြင်မှ ပြန်ထွက်လာတိုင်း Profile နှင့် လိပ်စာကို အမြဲ ပြန်ဖတ်မည်
    await _loadProfile();
  }

  Future<void> _sendPasswordReset() async {
    if (_email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email လိပ်စာ မရှိပါ။')));
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email ပို့ပြီးပါပြီ။'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email ပို့၍မရပါ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: _background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, color: _text),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  // Profile summary
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _text,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _email.isEmpty ? 'Email မရှိပါ' : _email,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _role.toUpperCase(),
                                  style: const TextStyle(
                                    color: _primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit Profile',
                          onPressed: () => _openRoute('/customer/profile/edit'),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Personal information
                  _buildSectionTitle('Personal Information'),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          title: 'Full Name',
                          value: _name,
                        ),
                        const Divider(height: 1, color: _border),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          title: 'Email Address',
                          value: _email,
                        ),
                        const Divider(height: 1, color: _border),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          value: _phone,
                        ),
                        const Divider(height: 1, color: _border),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          title: 'Service Address',
                          value: _fullAddress,
                        ),
                      ],
                    ),
                  ),

                  // Account menu
                  _buildSectionTitle('Account & Services'),

                  _buildMenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'ကိုယ်ရေးအချက်အလက် ပြင်ဆင်ရန်',
                    onTap: () => _openRoute('/customer/profile/edit'),
                  ),

                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'ပြုပြင်ရေးဝန်ဆောင်မှု လိပ်စာများ',
                    iconColor: const Color(0xFFEA8A16),
                    onTap: () => _openRoute('/customer/address'),
                  ),

                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Service Requests',
                    subtitle: 'Booking နှင့် ပြုပြင်မှုမှတ်တမ်းများ',
                    iconColor: const Color(0xFF0891B2),
                    onTap: () => context.push('/customer/service-requests'),
                  ),

                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Payment၊ Quotation နှင့် အခြားသတိပေးချက်များ',
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () => context.push('/customer/notifications'),
                  ),

                  _buildSectionTitle('Security'),

                  _buildMenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Password ပြန်လည်သတ်မှတ်ရန် Email ပို့မည်',
                    iconColor: const Color(0xFF64748B),
                    onTap: _sendPasswordReset,
                  ),

                  const SizedBox(height: 12),

                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'အကောင့်မှ ထွက်ရန်',
                    destructive: true,
                    showArrow: false,
                    onTap: _logout,
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      'Phaung Home Repair',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}