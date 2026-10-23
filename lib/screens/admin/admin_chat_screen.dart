import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const AdminChatScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _sending = false;
  DocumentReference<Map<String, dynamic>> get _chatRef => _firestore.collection('chats').doc(widget.customerId);

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    try {
      await _chatRef.set({'adminUnreadCount': 0, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      final unread = await _chatRef.collection('messages').where('senderRole', isEqualTo: 'customer').where('readByAdmin', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'readByAdmin': true});
      }
      if (unread.docs.isNotEmpty) await batch.commit();
    } catch (_) {}
  }

  Future<void> _send() async {
    final admin = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (admin == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final profile = await _firestore.collection('users').doc(admin.uid).get();
      final adminName = (profile.data()?['name'] ?? profile.data()?['displayName'] ?? 'Admin').toString();
      await _chatRef.set({
        'customerId': widget.customerId,
        'customerName': widget.customerName,
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': admin.uid,
        'customerUnreadCount': FieldValue.increment(1),
        'adminUnreadCount': 0,
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _chatRef.collection('messages').add({
        'senderId': admin.uid,
        'senderRole': 'admin',
        'senderName': adminName,
        'message': text,
        'createdAt': FieldValue.serverTimestamp(),
        'readByAdmin': true,
      });
    } catch (e) {
      _controller.text = text;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reply ပို့မရပါ။ Firestore Rules ကိုစစ်ပါ။ ($e)')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final stream = _chatRef.collection('messages').orderBy('createdAt').snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.customerName, style: const TextStyle(fontWeight: FontWeight.w700)), const Text('Customer Support Conversation', style: TextStyle(fontSize: 11, color: Colors.grey))])),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Messages ဖတ်မရပါ။ Firestore Rules ကိုစစ်ပါ။'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Center(child: Text('Customer က Message ပို့လာတဲ့အခါ ဒီနေရာမှာ ပြပါမယ်။'));
            return ListView.builder(
              padding: const EdgeInsets.all(14), itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final mine = data['senderRole'] == 'admin';
                final timestamp = data['createdAt'];
                final time = timestamp is Timestamp ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}' : '';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
                    decoration: BoxDecoration(color: mine ? const Color(0xFF2563EB) : Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Align(alignment: Alignment.centerLeft, child: Text((data['message'] ?? '').toString(), style: TextStyle(color: mine ? Colors.white : const Color(0xFF172033), fontSize: 14))),
                      if (time.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(time, style: TextStyle(color: mine ? Colors.white70 : Colors.grey, fontSize: 10))),
                    ]),
                  ),
                );
              },
            );
          },
        )),
        SafeArea(top: false, child: Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 5, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'Customer ကို ပြန်ဖြေပါ...', filled: true, fillColor: const Color(0xFFF3F6FA), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _sending ? null : _send, style: IconButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white), icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded)),
          ]),
        )),
      ]),
    );
  }
}
