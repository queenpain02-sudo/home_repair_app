import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ServiceRequestDetailScreen ကို ဒီဖိုင်နဲ့ folder တူရင်
// အောက်ပါ import ကို အသုံးပြုပါ။
// Folder မတူရင် မိမိ project ရှိ path နဲ့ ပြင်ပေးပါ။
import 'service_request_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationStream() {
    final uid = _uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Notification အမျိုးအစားကို စံပုံစံပြောင်းပေးခြင်း
  String _getType(Map<String, dynamic> data) {
    final raw =
        data['notificationType'] ?? data['type'] ?? data['category'] ?? 'other';

    return raw.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
  }

  String _getCategory(Map<String, dynamic> data) {
    final type = _getType(data);

    if (type.contains('payment') ||
        type.contains('paid') ||
        type.contains('refund') ||
        type.contains('transaction')) {
      return 'payment';
    }

    if (type.contains('quotation') ||
        type.contains('quote') ||
        type.contains('estimate')) {
      return 'quotation';
    }

    if (type.contains('technician') ||
        type.contains('worker') ||
        type.contains('assignment')) {
      return 'technician';
    }

    if (type.contains('invoice') || type.contains('receipt')) {
      return 'invoice';
    }

    if (type.contains('review') ||
        type.contains('rating') ||
        type.contains('feedback')) {
      return 'review';
    }

    if (type.contains('chat') || type.contains('message')) {
      return 'chat';
    }

    if (type.contains('promotion') ||
        type.contains('promo') ||
        type.contains('advert') ||
        type.contains('campaign')) {
      return 'promotion';
    }

    if (type.contains('repair') ||
        type.contains('complete') ||
        type.contains('arrival') ||
        type.contains('inspection')) {
      return 'repair';
    }

    if (type.contains('booking') ||
        type.contains('request') ||
        type.contains('cancel') ||
        type.contains('reject') ||
        type.contains('accept')) {
      return 'request';
    }

    return 'other';
  }

  bool _isRead(Map<String, dynamic> data) {
    return data['isRead'] == true || data['read'] == true;
  }

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final unreadDocs = docs.where((doc) => !_isRead(doc.data())).toList();

    if (unreadDocs.isEmpty) {
      _showMessage('ဖတ်ရန် Notification မရှိပါ။');
      return;
    }

    try {
      // Firestore batch တစ်ခုလျှင် 500 writes အောက်သာထားပါ။
      for (var start = 0; start < unreadDocs.length; start += 450) {
        final end = (start + 450 < unreadDocs.length)
            ? start + 450
            : unreadDocs.length;

        final batch = _firestore.batch();

        for (final doc in unreadDocs.sublist(start, end)) {
          batch.update(doc.reference, {
            'isRead': true,
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      _showMessage('Notification အားလုံးကို ဖတ်ပြီးပါပြီ။');
    } catch (e) {
      _showMessage('လုပ်ဆောင်၍မရပါ။ $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'quotation':
        return Icons.request_quote_rounded;
      case 'technician':
        return Icons.engineering_rounded;
      case 'repair':
        return Icons.handyman_rounded;
      case 'request':
        return Icons.assignment_rounded;
      case 'invoice':
        return Icons.receipt_long_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'promotion':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'payment':
        return Colors.green;
      case 'quotation':
        return Colors.deepPurple;
      case 'technician':
        return Colors.blue;
      case 'repair':
        return Colors.orange;
      case 'request':
        return Colors.teal;
      case 'invoice':
        return Colors.indigo;
      case 'review':
        return Colors.amber.shade800;
      case 'chat':
        return Colors.cyan.shade800;
      case 'promotion':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }

  String _categorySubtitle(String category) {
    switch (category) {
      case 'payment':
        return 'ငွေပေးချေမှုနှင့် ငွေပေးချေမှုအတည်ပြုချက်';
      case 'quotation':
        return 'ဈေးနှုန်းတင်ပြမှုနှင့် အတည်ပြုချက်';
      case 'technician':
        return 'Technician ခန့်အပ်မှုနှင့် ဝန်ထမ်းဆိုင်ရာ';
      case 'repair':
        return 'ပြုပြင်မှုအခြေအနေနှင့် အလုပ်ပြီးစီးမှု';
      case 'request':
        return 'Booking၊ Request နှင့် Cancel အခြေအနေ';
      case 'invoice':
        return 'Invoice နှင့် ငွေတောင်းခံလွှာ';
      case 'review':
        return 'Review နှင့် Rating';
      case 'chat':
        return 'Message အသစ်များ';
      case 'promotion':
        return 'Promotion နှင့် ကြော်ငြာများ';
      default:
        return 'အခြားအကြောင်းကြားချက်များ';
    }
  }

  int _unreadCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String category,
  ) {
    return docs.where((doc) {
      final data = doc.data();

      return !_isRead(data) &&
          (category == 'all' || _getCategory(data) == category);
    }).length;
  }

  void _openCategory(String category, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationCategoryDetailScreen(category: category, title: title),
      ),
    );
  }
  
  // 🛠️ Repair ပြီးဆုံးကြောင်း အတည်ပြုပြီး 1 ပတ်အကြာ Reminder ရက်သတ်မှတ်ခြင်း
Future<void> setRepairReminder(String requestId, String customerId, String serviceName) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // ယခုအချိန်မှစ၍ ၇ ရက် (၁ ပတ်) အကြာကို တွက်ချက်ခြင်း
    DateTime oneWeekLater = DateTime.now().add(const Duration(days: 7));

    // notifications collection ထဲသို့ reminder အဖြစ် ကြိုတင်ထည့်သွင်းခြင်း (သို့မဟုတ် Cloud Function ဖြင့် ဖတ်ရန်)
    await firestore.collection('notifications').add({
      'userId': customerId,
      'requestId': requestId,
      'type': 'service_reminder',
      'title': 'ဝန်ဆောင်မှု အခြေအနေ မေးမြန်းခြင်း',
      'message': 'သင်ပြုပြင်ခဲ့သော "$serviceName" ဝန်ဆောင်မှုမှာ ၁ ပတ်ပြည့်ပြီဖြစ်ပါသည်။ ယခုအခါ အဆင်ပြေပါရဲ့လားခင်ဗျာ?',
      'scheduledFor': Timestamp.fromDate(oneWeekLater), // ၁ ပတ်ပြည့်မည့်ရက်
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('1 ပတ်ပြည့် Reminder အောင်မြင်စွာ သတ်မှတ်ပြီးပါပြီ။');
  } catch (e) {
    debugPrint('Reminder error: $e');
  }
}
  Widget _buildCategoryTile({
    required String category,
    required String title,
    required String subtitle,
    required IconData icon,
    required int total,
    required int unread,
  }) {
    final color = _categoryColor(category);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCategory(category, title),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$total ခု',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (unread > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 25),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.grey.shade400,
                      size: 21,
                    ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('အကောင့်ဝင်ပြီးမှ Notification ကြည့်နိုင်ပါမည်။'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Notification ဖတ်၍မရပါ။\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final categories = <Map<String, dynamic>>[
            {
              'key': 'payment',
              'title': 'Payment',
              'subtitle': _categorySubtitle('payment'),
            },
            {
              'key': 'quotation',
              'title': 'Quotation',
              'subtitle': _categorySubtitle('quotation'),
            },
            {
              'key': 'technician',
              'title': 'Technician',
              'subtitle': _categorySubtitle('technician'),
            },
            {
              'key': 'repair',
              'title': 'Repair',
              'subtitle': _categorySubtitle('repair'),
            },
            {
              'key': 'request',
              'title': 'Booking & Request',
              'subtitle': _categorySubtitle('request'),
            },
            {
              'key': 'invoice',
              'title': 'Invoice',
              'subtitle': _categorySubtitle('invoice'),
            },
            {
              'key': 'review',
              'title': 'Review & Rating',
              'subtitle': _categorySubtitle('review'),
            },
            {
              'key': 'chat',
              'title': 'Chat',
              'subtitle': _categorySubtitle('chat'),
            },
            {
              'key': 'promotion',
              'title': 'Promotion',
              'subtitle': _categorySubtitle('promotion'),
            },
            {
              'key': 'other',
              'title': 'Other',
              'subtitle': _categorySubtitle('other'),
            },
          ];

          final allUnread = _unreadCount(docs, 'all');

          return RefreshIndicator(
            onRefresh: () async {
              await _notificationStream().first;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1769FF), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 39,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'သင့်အကြောင်းကြားချက်များ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'စုစုပေါင်း ${docs.length} ခု'
                              '  •  မဖတ်ရသေး $allUnread ခု',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'အမျိုးအစားအလိုက် ကြည့်ရန်',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: allUnread == 0
                          ? null
                          : () => _markAllAsRead(docs),
                      child: const Text('အားလုံးဖတ်ပြီး'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCategoryTile(
                  category: 'all',
                  title: 'All Notifications',
                  subtitle: 'အကြောင်းကြားချက်အားလုံးကို ကြည့်ရန်',
                  icon: Icons.notifications_rounded,
                  total: docs.length,
                  unread: allUnread,
                ),
                ...categories.map((item) {
                  final key = item['key'] as String;
                  final filtered = docs.where(
                    (doc) => _getCategory(doc.data()) == key,
                  );

                  return _buildCategoryTile(
                    category: key,
                    title: item['title'] as String,
                    subtitle: item['subtitle'] as String,
                    icon: _categoryIcon(key),
                    total: filtered.length,
                    unread: _unreadCount(docs, key),
                  );
                }),
                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 55,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Notification မရှိသေးပါ။',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// NOTIFICATION CATEGORY DETAIL SCREEN
// အမျိုးအစားတစ်ခုကို ဝင်ကြည့်သည့် သီးခြားစာမျက်နှာ
// ============================================================

class NotificationCategoryDetailScreen extends StatefulWidget {
  final String category;
  final String title;

  const NotificationCategoryDetailScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<NotificationCategoryDetailScreen> createState() =>
      _NotificationCategoryDetailScreenState();
}

class _NotificationCategoryDetailScreenState
    extends State<NotificationCategoryDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final uid = _uid;

    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _getType(Map<String, dynamic> data) {
    final raw =
        data['notificationType'] ?? data['type'] ?? data['category'] ?? 'other';

    return raw.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
  }

  String _getCategory(Map<String, dynamic> data) {
    final type = _getType(data);

    if (type.contains('payment') ||
        type.contains('paid') ||
        type.contains('refund') ||
        type.contains('transaction')) {
      return 'payment';
    }

    if (type.contains('quotation') ||
        type.contains('quote') ||
        type.contains('estimate')) {
      return 'quotation';
    }

    if (type.contains('technician') ||
        type.contains('worker') ||
        type.contains('assignment')) {
      return 'technician';
    }

    if (type.contains('invoice') || type.contains('receipt')) {
      return 'invoice';
    }

    if (type.contains('review') ||
        type.contains('rating') ||
        type.contains('feedback')) {
      return 'review';
    }

    if (type.contains('chat') || type.contains('message')) {
      return 'chat';
    }

    if (type.contains('promotion') ||
        type.contains('promo') ||
        type.contains('advert') ||
        type.contains('campaign')) {
      return 'promotion';
    }

    if (type.contains('repair') ||
        type.contains('complete') ||
        type.contains('arrival') ||
        type.contains('inspection')) {
      return 'repair';
    }

    if (type.contains('booking') ||
        type.contains('request') ||
        type.contains('cancel') ||
        type.contains('reject') ||
        type.contains('accept')) {
      return 'request';
    }

    return 'other';
  }

  bool _isRead(Map<String, dynamic> data) {
    return data['isRead'] == true || data['read'] == true;
  }

  IconData _icon(String category) {
    switch (category) {
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'quotation':
        return Icons.request_quote_rounded;
      case 'technician':
        return Icons.engineering_rounded;
      case 'repair':
        return Icons.handyman_rounded;
      case 'request':
        return Icons.assignment_rounded;
      case 'invoice':
        return Icons.receipt_long_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'promotion':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _color(String category) {
    switch (category) {
      case 'payment':
        return Colors.green;
      case 'quotation':
        return Colors.deepPurple;
      case 'technician':
        return Colors.blue;
      case 'repair':
        return Colors.orange;
      case 'request':
        return Colors.teal;
      case 'invoice':
        return Colors.indigo;
      case 'review':
        return Colors.amber.shade800;
      case 'chat':
        return Colors.cyan.shade800;
      case 'promotion':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is int) {
      date = DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (date == null) return '';

    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60 && !difference.isNegative) {
      return 'ယခုလေးတင်';
    }

    if (difference.inMinutes < 60 && !difference.isNegative) {
      return '${difference.inMinutes} မိနစ်အကြာ';
    }

    if (difference.inHours < 24 && !difference.isNegative) {
      return '${difference.inHours} နာရီအကြာ';
    }

    if (difference.inDays < 7 && !difference.isNegative) {
      return '${difference.inDays} ရက်အကြာ';
    }

    final d = date.toLocal();

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _markAsRead(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_isRead(doc.data())) return;

    try {
      await doc.reference.update({
        'isRead': true,
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showMessage('ဖတ်ပြီးကြောင်း သတ်မှတ်၍မရပါ။ $e');
    }
  }

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final unread = docs.where((doc) => !_isRead(doc.data())).toList();

    if (unread.isEmpty) {
      _showMessage('ဖတ်ရန် Notification မရှိပါ။');
      return;
    }

    try {
      for (var start = 0; start < unread.length; start += 450) {
        final end = (start + 450 < unread.length) ? start + 450 : unread.length;

        final batch = _firestore.batch();

        for (final doc in unread.sublist(start, end)) {
          batch.update(doc.reference, {
            'isRead': true,
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      _showMessage('အားလုံးကို ဖတ်ပြီးပါပြီ။');
    } catch (e) {
      _showMessage('လုပ်ဆောင်၍မရပါ။ $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    await _markAsRead(doc);

    if (!mounted) return;

    // Notification data ထဲမှာ Repair Request ID ပါမှ
    // Service Request Detail ကို ဖွင့်ပေးမည်။
    final requestId = data['requestId'] ?? data['serviceRequestId'];

    if (requestId != null && requestId.toString().trim().isNotEmpty) {
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceRequestDetailScreen(requestId: requestId.toString()),
          ),
        );
      } catch (e) {
        _showMessage('အသေးစိတ်စာမျက်နှာ ဖွင့်၍မရပါ။ $e');
      }

      return;
    }

    final category = _getCategory(data);

    if (category == 'chat') {
      _showMessage('Chat စာမျက်နှာသို့ သွားရန် Chat menu ကို အသုံးပြုပါ။');
    } else {
      _showMessage('ဒီ Notification အတွက် အသေးစိတ်စာမျက်နှာ မသတ်မှတ်ရသေးပါ။');
    }
  }

  Widget _notificationCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final category = _getCategory(data);
    final color = _color(category);

    final title = (data['title'] ?? data['subject'] ?? 'Notification')
        .toString();

    final message =
        (data['message'] ?? data['body'] ?? data['description'] ?? '')
            .toString();

    final read = _isRead(data);
    final createdAt = data['createdAt'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: read ? Colors.white : const Color(0xFFEAF2FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: read ? Colors.grey.shade200 : const Color(0xFFBBD2FF),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openNotification(doc),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_icon(category), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: read
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (!read)
                          TextButton(
                            onPressed: () => _markAsRead(doc),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'ဖတ်ပြီး',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.category == 'all' ? 'All Notifications' : widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? [];

              final docs = allDocs.where((doc) {
                return widget.category == 'all' ||
                    _getCategory(doc.data()) == widget.category;
              }).toList();

              final hasUnread = docs.any((doc) => !_isRead(doc.data()));

              return IconButton(
                tooltip: 'အားလုံးဖတ်ပြီး',
                onPressed: hasUnread ? () => _markAllAsRead(docs) : null,
                icon: const Icon(Icons.done_all_rounded),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Notification ဖတ်၍မရပါ။\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          final docs = allDocs.where((doc) {
            return widget.category == 'all' ||
                _getCategory(doc.data()) == widget.category;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 65,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ဒီအမျိုးအစားမှာ Notification မရှိသေးပါ။',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _stream().first;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return _notificationCard(docs[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
