import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_repair_app/screens/common/edit_profile_screen.dart';
import 'package:home_repair_app/screens/common/notification_list_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  final Color primaryColor = const Color(0xFF2563EB);
  final Color darkColor = const Color(0xFF0F172A);
  final Color backgroundColor = const Color(0xFFF4F7FE);

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      context.go('/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // STAT STREAMS
  // ============================================================

  Stream<int> _collectionCount(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _pendingPaymentCount() {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.trending_up_rounded, color: Colors.green.shade400, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your Home Repair Services efficiently',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          // Notification Icon
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: 'admin')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final unreadCount = docs
                  .where((doc) => !(doc.data()['isRead'] as bool? ?? false))
                  .length;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: IconButton(
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            constraints: const BoxConstraints(minWidth: 14),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationListScreen(
                          userId: 'admin',
                          title: 'Admin Notifications',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
              tooltip: 'Customer Chats',
              onPressed: () => context.push('/admin/chats'),
              icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Edit Profile Icon
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              tooltip: 'Edit Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(
                      collectionName: 'users',
                      userRole: 'admin',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
              tooltip: 'Logout',
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context),
              const SizedBox(height: 22),
              _buildSectionTitle(
                title: 'Overview',
                subtitle: 'Your business at a glance',
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  StreamBuilder<int>(
                    stream: _collectionCount('service_requests'),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        context: context,
                        title: 'Service Requests',
                        value: '${snapshot.data ?? 0}',
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF6366F1),
                        subtitle: 'Total requests',
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _pendingPaymentCount(),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        context: context,
                        title: 'Pending Payments',
                        value: '${snapshot.data ?? 0}',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF10B981),
                        subtitle: 'To verify',
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _collectionCount('technicians'),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        context: context,
                        title: 'Technicians',
                        value: '${snapshot.data ?? 0}',
                        icon: Icons.engineering_outlined,
                        color: const Color(0xFFF59E0B),
                        subtitle: 'Registered staff',
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _collectionCount('reviews'),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        context: context,
                        title: 'Reviews',
                        value: '${snapshot.data ?? 0}',
                        icon: Icons.star_outline_rounded,
                        color: const Color(0xFFEC4899),
                        subtitle: 'Feedback count',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                title: 'Quick Management',
                subtitle: 'Manage your repair service business',
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context: context,
                icon: Icons.category_outlined,
                iconColor: const Color(0xFF2563EB),
                title: 'Service Categories',
                subtitle: 'Manage repair service categories',
                onTap: () => context.push('/admin/service-categories'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.home_repair_service_outlined,
                iconColor: const Color(0xFF4F46E5),
                title: 'Services',
                subtitle: 'Manage home repair services',
                onTap: () => context.push('/admin/services'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.engineering_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: 'Technicians',
                subtitle: 'Manage technicians and assignments',
                onTap: () => context.push('/admin/technicians'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: 'Service Requests',
                subtitle: 'View and manage customer requests',
                onTap: () => context.push('/admin/service-requests'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF059669),
                title: 'Payment Verification',
                subtitle: 'Verify customer payments',
                onTap: () => context.push('/admin/payment-verification'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.local_offer_outlined,
                iconColor: const Color(0xFF0891B2),
                title: 'Promocodes',
                subtitle: 'Create and manage labor discount codes',
                onTap: () => context.push('/admin/add-promo'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.rate_review_outlined,
                iconColor: const Color(0xFFEAB308),
                title: 'Reviews & Ratings',
                subtitle: 'View reviews and technician ratings',
                onTap: () => context.push('/admin/reviews'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.campaign_outlined,
                iconColor: const Color(0xFFDB2777),
                title: 'Advertisements',
                subtitle: 'Manage customer home advertisements',
                onTap: () => context.push('/admin/advertisements'),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                icon: Icons.report_problem_outlined,
                iconColor: const Color(0xFFEF4444),
                title: 'Customer Complaints',
                subtitle: 'Review and resolve customer complaints',
                onTap: () => context.push('/admin/complaints'),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Control Center',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage services, technicians, customer '
                            'requests, payments, reviews, advertisements '
                            'and complaints from one place.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}