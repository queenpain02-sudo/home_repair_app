import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;
  final String serviceName;
  final String categoryId;
  final String categoryName;
  final String description;
  final dynamic price;
  final String priceType;
  final int duration;
  final String imageUrl;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.price,
    required this.priceType,
    required this.duration,
    required this.imageUrl,
  });

  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF6F8FC);
  static const Color _text = Color(0xFF172033);
  static const Color _muted = Color(0xFF64748B);

  String _formatPrice() {
    if (priceType == 'quote') {
      return 'Get a Quote';
    }

    final num? amount = price is num
        ? price as num
        : num.tryParse(price?.toString() ?? '');

    if (amount == null) {
      return 'Price not set';
    }

    final formatted = _formatNumber(amount);

    if (priceType == 'starting_from') {
      return 'From $formatted MMK';
    }

    return '$formatted MMK';
  }

  String _formatNumber(num amount) {
    final value = amount.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);

      final remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Service Details',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _text,
            size: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryBadge(),

                  const SizedBox(height: 12),

                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: _primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Professional home repair service',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.payments_outlined,
                          title: 'Service Price',
                          value: _formatPrice(),
                          iconColor: const Color(0xFF16A34A),
                          iconBackground: const Color(0xFFDCFCE7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule_rounded,
                          title: 'Duration',
                          value: duration > 0
                              ? '$duration min'
                              : 'To be confirmed',
                          iconColor: _primary,
                          iconBackground: const Color(0xFFDBEAFE),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  _SectionCard(
                    icon: Icons.description_outlined,
                    title: 'About This Service',
                    child: Text(
                      description.trim().isNotEmpty
                          ? description.trim()
                          : 'No description is available for this service yet. Please contact our team for more information.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    icon: Icons.checklist_rounded,
                    title: 'Before You Request',
                    child: const Column(
                      children: [
                        _InfoRow(
                          icon: Icons.check_circle_outline_rounded,
                          text:
                              'Choose a service that matches your repair problem.',
                        ),
                        SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          text:
                              'Provide the correct address where the repair is needed.',
                        ),
                        SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.phone_in_talk_outlined,
                          text:
                              'Keep your phone available for technician contact.',
                        ),
                        SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.receipt_long_outlined,
                          text:
                              'The final price may be confirmed after inspection.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          color: _primary,
                          size: 25,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Need help? Submit a service request and our team can assist you with the next steps.',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
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

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  '/customer/service-request',
                  extra: {
                    'serviceId': serviceId,
                    'serviceName': serviceName,
                    'categoryId': categoryId,
                    'categoryName': categoryName,
                    'description': description,
                    'price': price,
                    'priceType': priceType,
                    'duration': duration,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handyman_outlined, size: 21),
                  SizedBox(width: 10),
                  Text(
                    'Request This Service',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
      width: double.infinity,
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.trim().isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            )
          else
            _buildImagePlaceholder(),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_repair_service_rounded,
                    size: 17,
                    color: _primary,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Phaung Home Repair',
                    style: TextStyle(
                      color: _text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFE8EFFB),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_repair_service_rounded, size: 76, color: _primary),
          SizedBox(height: 10),
          Text(
            'Home Repair Service',
            style: TextStyle(color: _primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, color: _primary, size: 15),
          const SizedBox(width: 6),
          Text(
            categoryName.trim().isNotEmpty ? categoryName : 'Home Service',
            style: const TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: const Color(0xFF2563EB)),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
