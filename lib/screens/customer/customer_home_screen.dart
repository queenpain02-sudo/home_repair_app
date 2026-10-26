import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_category_model.dart';
import '../../services/service_category_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // Premium Theme Colors
  final Color primaryColor = const Color(0xFF0F4C5C);
  final Color darkColor = const Color(0xFF0F172A);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardBackgroundColor = Colors.white;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ServiceCategoryService _categoryService = ServiceCategoryService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Advertisement Slider
  final PageController _adPageController = PageController();
  Timer? _adTimer;
  int _currentAdIndex = 0;
  int _lastAdvertisementCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _adPageController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _advertisementStream() {
    return _firestore.collection('advertisements').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['active'] == true || data['isActive'] == true;
      }).toList();
    });
  }

  void _startAdvertisementAutoPlay(int itemCount) {
    if (itemCount <= 1) return;
    if (_lastAdvertisementCount == itemCount && _adTimer != null && _adTimer!.isActive) return;

    _adTimer?.cancel();
    _lastAdvertisementCount = itemCount;

    _adTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_adPageController.hasClients) return;
      _currentAdIndex = (_currentAdIndex + 1) % itemCount;
      _adPageController.animateToPage(
        _currentAdIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAdvertisementAutoPlay() {
    _adTimer?.cancel();
    _adTimer = null;
    _lastAdvertisementCount = 0;
  }

  Stream<int> _unreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.where((doc) => doc.data()['isRead'] != true).length);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
        }
        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text('ရှာမတွေ့ပါ။', style: TextStyle(color: Colors.grey.shade500)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ရှာဖွေတွေ့ရှိမှု (${filteredDocs.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
            const SizedBox(height: 10),
            ...filteredDocs.map((doc) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                title: Text(doc.data()['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(doc.data()['description'] ?? '', maxLines: 1, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: () {},
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildAdvertisementSection() {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _advertisementStream(),
      builder: (context, snapshot) {
        final advertisements = snapshot.data ?? [];
        if (advertisements.isEmpty) {
          _resetAdvertisementAutoPlay();
          return const SizedBox.shrink();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startAdvertisementAutoPlay(advertisements.length);
        });

        return Column(
          children: [
            SizedBox(
              height: 155,
              child: PageView.builder(
                controller: _adPageController,
                itemCount: advertisements.length,
                onPageChanged: (index) => setState(() => _currentAdIndex = index),
                itemBuilder: (context, index) {
                  final data = advertisements[index].data();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Special Offer', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['title'] ?? 'Special Repair Promotion',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['description'] ?? 'အထူးဝန်ဆောင်မှုများကို ယခုပဲ ရယူလိုက်ပါ။',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(advertisements.length, (index) {
                return Container(
                  width: _currentAdIndex == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentAdIndex == index ? primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    return StreamBuilder<List<ServiceCategoryModel>>(
      stream: _categoryService.getCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        
        return SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChipItem('All', true),
              ...categories.map((cat) => _buildCategoryChipItem(cat.name, false)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChipItem(String name, bool isAll) {
    final isSelected = _selectedCategory == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProjectsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('services').limit(5).snapshots(),
      builder: (context, snapshot) {
        final services = snapshot.data?.docs ?? [];
        if (services.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            itemBuilder: (context, index) {
              final doc = services[index];
              final service = doc.data();
              final serviceId = doc.id;
              final name = service['name']?.toString() ?? 'Repair Service';
              final price = service['price'] ?? 0;
              final imageUrl = service['imageUrl']?.toString() ?? '';
              final description = service['description']?.toString() ?? '';
              final categoryId = service['categoryId']?.toString() ?? '';
              final categoryName = service['categoryName']?.toString() ?? '';
              final priceType = service['priceType']?.toString() ?? 'fixed';
              final duration = service['duration'] ?? 0;

              return GestureDetector(
                onTap: () {
                  context.push(
                    '/customer/service-detail',
                    extra: {
                      'serviceId': serviceId,
                      'serviceName': name,
                      'categoryId': categoryId,
                      'categoryName': categoryName,
                      'description': description,
                      'price': price,
                      'priceType': priceType,
                      'duration': duration,
                      'imageUrl': imageUrl,
                    },
                  );
                },
                child: Container(
                  width: 210,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholderImage())
                            : _placeholderImage(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$price Ks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  

  Widget _placeholderImage() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Icon(Icons.image_rounded, color: Colors.grey.shade400, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/customer/chat');
          if (index == 2) context.push('/customer/service-requests');
          if (index == 3) context.push('/customer/profile');
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _userProfileStream(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final name = data?['name']?.toString() ?? 'Jane Cooper';
                  final profileImage = data?['profileImage']?.toString() ?? '';

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                        child: profileImage.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hello', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
                        ],
                      ),
                      const Spacer(),
                      StreamBuilder<int>(
                        stream: _unreadNotificationCount(),
                        builder: (context, notifSnapshot) {
                          final count = notifSnapshot.data ?? 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: IconButton(
                              onPressed: () => context.push('/customer/notifications'),
                              icon: Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                child: Icon(Icons.notifications_none_rounded, color: darkColor, size: 22),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(onPressed: () => _searchController.clear(), icon: const Icon(Icons.clear, size: 16))
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(12),
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_searchQuery.isNotEmpty) ...[
                _buildSearchResults(),
              ] else ...[
                _buildAdvertisementSection(),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
                    TextButton(
                      onPressed: () => context.push('/customer/services', extra: {'categoryId': '', 'categoryName': 'All Services'}),
                      child: Text('See all', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCategoryChips(),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Project', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
                    TextButton(
                      onPressed: () => context.push('/customer/services', extra: {'categoryId': '', 'categoryName': 'All Services'}),
                      child: Text('See all', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFeaturedProjectsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}