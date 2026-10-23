import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServiceListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ServiceListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF6F8FC);
  static const Color _text = Color(0xFF172033);
  static const Color _muted = Color(0xFF788397);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic price, String priceType) {
    if (priceType == 'quote') {
      return 'Get a Quote';
    }

    final amount = price is num
        ? price.toDouble()
        : double.tryParse(price?.toString() ?? '') ?? 0;

    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );

    if (priceType == 'starting_from') {
      return 'From $formatted MMK';
    }

    return '$formatted MMK';
  }

  void _openServiceDetail(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    context.push(
      '/customer/service-detail',
      extra: {
        'serviceId': doc.id,
        'serviceName': data['name']?.toString() ?? 'Service',
        'categoryId': widget.categoryId,
        'categoryName': widget.categoryName.isNotEmpty
            ? widget.categoryName
            : (data['categoryName']?.toString() ?? 'Service'),
        'description': data['description']?.toString() ?? '',
        'price': data['price'],
        'priceType': data['priceType']?.toString() ?? 'fixed',
        'duration': (data['duration'] as num?)?.toInt() ?? 0,
        'imageUrl': data['imageUrl']?.toString() ?? '',
      },
    );
  }

  bool _isActive(Map<String, dynamic> data) {
    return data['active'] != false &&
        data['isActive'] != false &&
        data['isAvailable'] != false;
  }

  bool _matchesCategory(Map<String, dynamic> data) {
    if (widget.categoryId.trim().isEmpty) {
      return true;
    }

    final targetId = widget.categoryId.toLowerCase().trim();

    final docCategoryId =
        data['categoryId']?.toString().toLowerCase().trim() ?? '';

    if (docCategoryId == targetId) {
      return true;
    }

    final targetName = widget.categoryName.toLowerCase().trim();

    final docCategoryName =
        data['categoryName']?.toString().toLowerCase().trim() ?? '';

    return targetName.isNotEmpty && docCategoryName == targetName;
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.trim().isEmpty) {
      return true;
    }

    final query = _searchQuery.toLowerCase().trim();

    final name = data['name']?.toString().toLowerCase() ?? '';
    final description = data['description']?.toString().toLowerCase() ?? '';
    final category = data['categoryName']?.toString().toLowerCase() ?? '';

    return name.contains(query) ||
        description.contains(query) ||
        category.contains(query);
  }

  Widget _buildSearchBox() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildBanner(int serviceCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Home Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.categoryName.isNotEmpty
                      ? widget.categoryName
                      : 'Find the right service for your home',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$serviceCount services available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: Colors.white,
              size: 39,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final name = data['name']?.toString() ?? 'Service';
    final description = data['description']?.toString() ?? '';
    final price = data['price'];
    final priceType = data['priceType']?.toString() ?? 'fixed';
    final duration = (data['duration'] as num?)?.toInt() ?? 0;
    final imageUrl = data['imageUrl']?.toString() ?? '';

    final priceColor = priceType == 'quote'
        ? const Color(0xFF7C3AED)
        : _primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openServiceDetail(context, doc),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 100,
                    height: 112,
                    color: const Color(0xFFEAF1FF),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return const Icon(
                                Icons.home_repair_service_rounded,
                                color: _primary,
                                size: 37,
                              );
                            },
                          )
                        : const Icon(
                            Icons.home_repair_service_rounded,
                            color: _primary,
                            size: 37,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        _formatPrice(price, priceType),
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (duration > 0) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: _muted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$duration min',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA4B2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 45),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF1FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primary, size: 43),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesQuery = FirebaseFirestore.instance.collection('services');

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: _background,
        elevation: 0,
        centerTitle: false,
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
        title: Text(
          widget.categoryName.isNotEmpty ? widget.categoryName : 'All Services',
          style: const TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: servicesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              title: 'Unable to load services',
              subtitle:
                  'အင်တာနက်ချိတ်ဆက်မှုနှင့် Firebase permission ကို စစ်ဆေးပေးပါ။\n${snapshot.error}',
              icon: Icons.cloud_off_rounded,
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final activeServices = docs
              .where((doc) => _isActive(doc.data()))
              .toList();

          final categoryServices = activeServices
              .where((doc) => _matchesCategory(doc.data()))
              .toList();

          categoryServices.sort((a, b) {
            final aOrder = (a.data()['sortOrder'] as num?)?.toInt() ?? 0;
            final bOrder = (b.data()['sortOrder'] as num?)?.toInt() ?? 0;

            return aOrder.compareTo(bOrder);
          });

          final filteredServices = categoryServices
              .where((doc) => _matchesSearch(doc.data()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                child: Column(
                  children: [
                    _buildBanner(categoryServices.length),
                    const SizedBox(height: 16),
                    _buildSearchBox(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Available Services',
                            style: TextStyle(
                              color: _text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${filteredServices.length} found',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredServices.isEmpty
                    ? _buildEmptyState(
                        title: _searchQuery.isNotEmpty
                            ? 'No matching services'
                            : 'No services available',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'အခြားစကားလုံးဖြင့် ရှာကြည့်ပါ။'
                            : 'ဒီအမျိုးအစားမှာ ဝန်ဆောင်မှု မရှိသေးပါ။',
                        icon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.home_repair_service_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        itemCount: filteredServices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildServiceCard(
                            context,
                            filteredServices[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
