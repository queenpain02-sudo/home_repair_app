import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// One private support conversation per signed-in customer.
/// Firestore path: chats/{customerUid}/messages/{messageId}
class CustomerSupportChatScreen extends StatefulWidget {
  const CustomerSupportChatScreen({super.key});

  @override
  State<CustomerSupportChatScreen> createState() =>
      _CustomerSupportChatScreenState();
}

class _CustomerSupportChatScreenState extends State<CustomerSupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  bool _sending = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      _firestore.collection('chats').doc(_user!.uid);

  @override
  void initState() {
    super.initState();
    _ensureChatExists();
  }

  Future<void> _ensureChatExists() async {
    final user = _user;
    if (user == null) return;
    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final data = profile.data() ?? <String, dynamic>{};
      final name = (data['name'] ?? data['displayName'] ?? user.displayName ??
              user.email?.split('@').first ?? 'Customer')
          .toString();
      await _chatRef.set({
        'customerId': user.uid,
        'customerName': name,
        'customerEmail': user.email ?? '',
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'customerUnreadCount': 0,
        'adminUnreadCount': 0,
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // The chat can still render; a permission/network message appears on send.
    }
  }

  Future<void> _sendMessage() async {
    final user = _user;
    final text = _messageController.text.trim();
    if (user == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();
    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final data = profile.data() ?? <String, dynamic>{};
      final name = (data['name'] ?? data['displayName'] ?? user.displayName ??
              user.email?.split('@').first ?? 'Customer')
          .toString();
      final chatRef = _chatRef;
      await chatRef.set({
        'customerId': user.uid,
        'customerName': name,
        'customerEmail': user.email ?? '',
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': user.uid,
        'adminUnreadCount': FieldValue.increment(1),
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await chatRef.collection('messages').add({
        'senderId': user.uid,
        'senderRole': 'customer',
        'senderName': name,
        'message': text,
        'createdAt': FieldValue.serverTimestamp(),
        'readByAdmin': false,
      });
    } catch (e) {
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message ပို့မရပါ။ Firebase Rules/Internet ကိုစစ်ပါ။ ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Chat အသုံးပြုရန် Login ဝင်ပါ။')));
    }

    final messages = _chatRef.collection('messages').orderBy('createdAt');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE0ECFF),
            child: Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB)),
          ),
          SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chat with Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Phaung Home Repair Support', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(14)),
          child: const Row(children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('ဒီ Chat ကို သင်နဲ့ Admin သာ မြင်နိုင်ပါတယ်။', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)))),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: messages.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Chat ကို ဖွင့်မရပါ။ Firestore Rules ကိုစစ်ပါ။'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 54, color: Color(0xFF93A4BD)),
                    SizedBox(height: 12),
                    Text('မင်္ဂလာပါ!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('ဝန်ဆောင်မှုနဲ့ပတ်သက်ပြီး မေးမြန်းလိုတာကို စာပို့နိုင်ပါတယ်။', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ]),
                ));
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final mine = data['senderId'] == user.uid;
                  final message = (data['message'] ?? '').toString();
                  final time = data['createdAt'];
                  final timeText = time is Timestamp
                      ? '${time.toDate().hour.toString().padLeft(2, '0')}:${time.toDate().minute.toString().padLeft(2, '0')}'
                      : '';
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4), bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Align(alignment: Alignment.centerLeft, child: Text(message, style: TextStyle(color: mine ? Colors.white : const Color(0xFF172033), fontSize: 14, height: 1.35))),
                        if (timeText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(timeText, style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.grey))),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -3))]),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'စာရေးပါ...', filled: true, fillColor: const Color(0xFFF3F6FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              )),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _sendMessage,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, minimumSize: const Size(48, 48)),
                icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
