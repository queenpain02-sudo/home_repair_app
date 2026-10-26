import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============================================================
// AUTH
// ============================================================

import 'package:home_repair_app/screens/auth/login_screen.dart';
import 'package:home_repair_app/screens/auth/register_screen.dart';

// ============================================================
// SPLASH
// ============================================================

import 'package:home_repair_app/screens/splash/splash_screen.dart';

// ============================================================
// CUSTOMER
// ============================================================

import 'package:home_repair_app/screens/customer/customer_home_screen.dart';
import 'package:home_repair_app/screens/customer/customer_promo_screen.dart';
import 'package:home_repair_app/screens/customer/service_list_screen.dart';
import 'package:home_repair_app/screens/customer/service_detail_screen.dart';
import 'package:home_repair_app/screens/customer/service_request_screen.dart';
import 'package:home_repair_app/screens/customer/service_request_list_screen.dart';

import 'package:home_repair_app/screens/customer/service_request_detail_screen.dart'
    as customer_request_detail;

import 'package:home_repair_app/screens/customer/payment_screen.dart';
import 'package:home_repair_app/screens/customer/invoice_screen.dart';
import 'package:home_repair_app/screens/customer/review_screen.dart';
import 'package:home_repair_app/screens/customer/customer_profile_screen.dart';
import 'package:home_repair_app/screens/customer/customer_edit_profile_screen.dart';
import 'package:home_repair_app/screens/customer/notification_screen.dart';
import 'package:home_repair_app/screens/customer/customer_address_screen.dart';
import 'package:home_repair_app/screens/customer/customer_quotation_screen.dart';
import 'package:home_repair_app/screens/chat/customer_support_chat_screen.dart';

// ============================================================
// ADMIN
// ============================================================

import 'package:home_repair_app/screens/admin/admin_home_screen.dart';
import 'package:home_repair_app/screens/admin/admin_add_promo_screen.dart';
import 'package:home_repair_app/screens/admin/service_management_screen.dart';
import 'package:home_repair_app/screens/admin/service_category_management_screen.dart';
import 'package:home_repair_app/screens/admin/service_request_management_screen.dart';

import 'package:home_repair_app/screens/admin/service_request_detail_screen.dart'
    as admin_request_detail;

import 'package:home_repair_app/screens/admin/technician_management_screen.dart';
import 'package:home_repair_app/screens/admin/payment_verification_screen.dart';
import 'package:home_repair_app/screens/admin/review_management_screen.dart';
import 'package:home_repair_app/screens/admin/advertisement_management_screen.dart';
import 'package:home_repair_app/screens/admin/admin_chat_inbox_screen.dart';
import 'package:home_repair_app/screens/admin/admin_chat_screen.dart';
import 'package:home_repair_app/screens/admin/complaint_management_screen.dart';


// ============================================================
// TECHNICIAN
// ============================================================

import 'package:home_repair_app/screens/technician/technician_home_screen.dart';

// ============================================================
// ROUTER
// ============================================================

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',

  routes: [
    GoRoute(
  path: '/customer/promos',
  builder: (context, state) => const CustomerPromoScreen(),
),
    GoRoute(path: '/admin/add-promo', builder: (context, state) => const AdminAddPromoScreen()),
    // ============================================================
    // AUTH
    // ============================================================

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterScreen();
      },
    ),

    // ============================================================
    // SPLASH
    // ============================================================
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    // ============================================================
    // CUSTOMER HOME
    // ============================================================
    GoRoute(
      path: '/customer',
      builder: (context, state) {
        return const CustomerHomeScreen();
      },
    ),
// ============================================================
    // CUSTOMER - INVOICE
    // ============================================================
    GoRoute(
      path: '/customer/invoice',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? <String, dynamic>{};
        final requestId = extra['requestId']?.toString() ?? '';
        return InvoiceScreen(requestId: requestId);
      },
    ),
    // ============================================================
    // CUSTOMER - ADMIN SUPPORT CHAT
    // ============================================================
    GoRoute(
      path: '/customer/chat',
      builder: (context, state) => const CustomerSupportChatScreen(),
    ),

    // ============================================================
    // CUSTOMER - QUOTATION
    // ============================================================
    GoRoute(
      path: '/customer/quotation',
      builder: (context, state) {
        final requestId = state.uri.queryParameters['requestId'] ?? '';

        return CustomerQuotationScreen(requestId: requestId);
      },
    ),

    // ============================================================
    // CUSTOMER - SERVICES
    // ============================================================
    GoRoute(
      path: '/customer/services',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? <String, dynamic>{};

        return ServiceListScreen(
          categoryId: extra['categoryId']?.toString() ?? '',
          categoryName: extra['categoryName']?.toString() ?? '',
        );
      },
    ),

    // ============================================================
    // CUSTOMER - SERVICE DETAIL
    // ============================================================
    GoRoute(
      path: '/customer/service-detail',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? <String, dynamic>{};

        final durationValue = extra['duration'];

        int duration = 0;

        if (durationValue is num) {
          duration = durationValue.toInt();
        } else {
          duration = int.tryParse(durationValue?.toString() ?? '0') ?? 0;
        }

        return ServiceDetailScreen(
          serviceId: extra['serviceId']?.toString() ?? '',
          serviceName: extra['serviceName']?.toString() ?? '',
          categoryId: extra['categoryId']?.toString() ?? '',
          categoryName: extra['categoryName']?.toString() ?? '',
          description: extra['description']?.toString() ?? '',
          price: extra['price'],
          priceType: extra['priceType']?.toString() ?? 'fixed',
          duration: duration,
          imageUrl: extra['imageUrl']?.toString() ?? '',
        );
      },
    ),

    // ============================================================
    // CUSTOMER - SERVICE REQUEST
    // ============================================================
    GoRoute(
      path: '/customer/service-request',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? <String, dynamic>{};

        final durationValue = extra['duration'];

        int duration = 0;

        if (durationValue is num) {
          duration = durationValue.toInt();
        } else {
          duration = int.tryParse(durationValue?.toString() ?? '0') ?? 0;
        }

        return ServiceRequestScreen(
          serviceId: extra['serviceId']?.toString() ?? '',
          serviceName: extra['serviceName']?.toString() ?? '',
          categoryId: extra['categoryId']?.toString() ?? '',
          categoryName: extra['categoryName']?.toString() ?? '',
          description: extra['description']?.toString() ?? '',
          price: extra['price'],
          priceType: extra['priceType']?.toString() ?? 'fixed',
          duration: duration,
        );
      },
    ),

    // ============================================================
    // CUSTOMER - SERVICE REQUEST LIST
    // ============================================================
    GoRoute(
      path: '/customer/service-requests',
      builder: (context, state) {
        return const ServiceRequestListScreen();
      },
    ),

    // ============================================================
    // CUSTOMER - SERVICE REQUEST DETAIL
    // ============================================================
    GoRoute(
      path: '/customer/service-request-detail',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? <String, dynamic>{};

        return customer_request_detail.ServiceRequestDetailScreen(
          requestId: extra['requestId']?.toString() ?? '',
        );
      },
    ),
// ============================================================
    // CUSTOMER - PAYMENT
    // ============================================================
    GoRoute(
      path: '/customer/payment',
      builder: (context, state) {
        // 1. URL Query Parameter မှ requestId ကို အရင်ရှာမည်
        String? requestId = state.uri.queryParameters['requestId'];

        // 2. အကယ်၍ query parameter မပါလာလျှင် extra မှ ဆွဲထုတ်မည်
        if (requestId == null || requestId.isEmpty) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            requestId = extra['requestId']?.toString();
          } else if (extra is Map) {
            requestId = extra['requestId']?.toString();
          }
        }

        // 3. PaymentScreen သို့ requestId ကို ပို့ဆောင်မည်
        return PaymentScreen(
          requestId: requestId,
        );
      },
    ),
    // ============================================================
    // CUSTOMER - REVIEW / RATING
    // ============================================================
    GoRoute(
      path: '/customer/review',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? <String, dynamic>{};

        return ReviewScreen(
          requestId: extra['requestId']?.toString() ?? '',
          paymentId: extra['paymentId']?.toString() ?? '',
          serviceName: extra['serviceName']?.toString() ?? '',
          technicianId: extra['technicianId']?.toString() ?? '',
          technicianName: extra['technicianName']?.toString() ?? 'Technician',
        );
      },
    ),

    // ============================================================
    // CUSTOMER - PROFILE
    // ============================================================
    GoRoute(
      path: '/customer/profile',
      builder: (context, state) {
        return const CustomerProfileScreen();
      },
    ),

    // ============================================================
    // CUSTOMER - EDIT PROFILE
    // ============================================================
    GoRoute(
      path: '/customer/profile/edit',
      builder: (context, state) {
        return const CustomerEditProfileScreen();
      },
    ),

    // ============================================================
    // CUSTOMER - NOTIFICATIONS
    // ============================================================
    GoRoute(
      path: '/customer/notifications',
      builder: (context, state) {
        return const NotificationScreen();
      },
    ),

    // ============================================================
    // CUSTOMER - ADDRESS
    // ============================================================
    GoRoute(
      path: '/customer/address',
      builder: (context, state) {
        return const CustomerAddressScreen();
      },
    ),

    // ============================================================
    // ADMIN HOME
    // ============================================================
    GoRoute(
      path: '/admin',
      builder: (context, state) {
        return const AdminHomeScreen();
      },
    ),

    // ============================================================
    // ADMIN - CUSTOMER CHAT INBOX
    // ============================================================
    GoRoute(
      path: '/admin/chats',
      builder: (context, state) => const AdminChatInboxScreen(),
    ),
    GoRoute(
      path: '/admin/chats/:customerId',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? <String, dynamic>{};
        return AdminChatScreen(
          customerId: state.pathParameters['customerId'] ?? '',
          customerName: extra['customerName']?.toString() ?? 'Customer',
        );
      },
    ),

    // ============================================================
    // ADMIN - SERVICE MANAGEMENT
    // ============================================================
    GoRoute(
      path: '/admin/services',
      builder: (context, state) {
        return const ServiceManagementScreen();
      },
    ),

    // ============================================================
    // ADMIN - SERVICE CATEGORY MANAGEMENT
    // ============================================================
    GoRoute(
      path: '/admin/service-categories',
      builder: (context, state) {
        return const ServiceCategoryManagementScreen();
      },
    ),
        GoRoute(
      path: '/admin/compliantmanagement',
      builder: (context, state) {
        return const ComplaintManagementScreen();
      },
    ),
    // ============================================================
    // ADMIN - SERVICE REQUEST MANAGEMENT
    // ============================================================
    GoRoute(
      path: '/admin/service-requests',
      builder: (context, state) {
        return ServiceRequestManagementScreen();
      },
    ),

    // ============================================================
    // ADMIN - SERVICE REQUEST DETAIL
    // ============================================================
    GoRoute(
      path: '/admin/service-request-detail',
      builder: (context, state) {
        final extra =
            state.extra as Map<String, dynamic>? ?? <String, dynamic>{};

        return admin_request_detail.ServiceRequestDetailScreen(
          requestId: extra['requestId']?.toString() ?? '',
        );
      },
    ),

    // ============================================================
    // ADMIN - TECHNICIAN MANAGEMENT
    // ============================================================
    GoRoute(
      path: '/admin/technicians',
      builder: (context, state) {
        return const TechnicianManagementScreen();
      },
    ),

    // ============================================================
    // ADMIN - PAYMENT VERIFICATION
    // ============================================================
    GoRoute(
      path: '/admin/payment-verification',
      builder: (context, state) {
        return PaymentVerificationScreen();
      },
    ),

    // ============================================================
    // ADMIN - REVIEWS
    // ============================================================
    GoRoute(
      path: '/admin/reviews',
      builder: (context, state) {
        return const ReviewManagementScreen();
      },
    ),

    // ============================================================
    // ADMIN - ADVERTISEMENTS
    // ============================================================
    GoRoute(
      path: '/admin/advertisements',
      builder: (context, state) {
        return const AdvertisementManagementScreen();
      },
    ),

    // ============================================================
    // TECHNICIAN
    // ============================================================
    GoRoute(
      path: '/technician',
      builder: (context, state) {
        return const TechnicianHomeScreen();
      },
    ),
  ],

  // ============================================================
  // ERROR PAGE
  // ============================================================
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/customer');
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  },
);

class AppRouter {
  static GoRouter get router => appRouter;
}