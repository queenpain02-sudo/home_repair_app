import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String technicianName;
  const ChatScreen({
    super.key,
    this.technicianName = "ဦးကျော်စွာ (အဲကွန်း ကျွမ်းကျင်သူ)",
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Chat Message နမူနာ စာရင်း
  final List<Map<String, dynamic>> _messages = [
    {
      "sender": "technician",
      "text": "မင်္ဂလာပါခင်ဗျ။ ကျွန်တော် လာနေပါပြီ ခင်ဗျာ။",
      "time": "10:15 AM",
    },
    {
      "sender": "customer",
      "text":
          "ဟုတ်ကဲ့ ကျေးဇူးပါဆရာ။ အိမ်ရှောက်နား ရောက်ရင် လှမ်းပြောပေးပါနော်။",
      "time": "10:16 AM",
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        "sender": "customer",
        "text": _messageController.text.trim(),
        "time": TimeOfDay.now().format(context),
      });
      _messageController.clear();
    });
  }

  // Masked Calling ခေါ်ဆိုသည့် ပုံစံ (Privacy ကာကွယ်ရန် Virtual Number ဖြင့် ချိတ်ဆက်ခြင်း)
  void _makeMaskedCall() {
    showDialog(
      context: C0ntextFromSomewhereOrBuildContext(context), // Flutter context
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("လုံခြုံရေးဖုန်းခေါ်ဆိုမှု (Masked Call)"),
          content: Text(
            "သင်၏ ကိုယ်ရေးကိုယ်တာ ဖုန်းနံပါတ် မပေါ်စေရန် App ၏ Proxy နံပါတ်ဖြင့် ${widget.technicianName} ထံသို့ ချိတ်ဆက်ပေးနေပါသည်...",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ပိတ်မည်"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ဖုန်းခေါ်ဆိုနေပါပြီ...")),
                );
              },
              child: const Text(
                "ဆက်လက်ခေါ်ဆိုမည်",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  BuildContext C0ntextFromSomewhereOrBuildContext(BuildContext ctx) => ctx;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.technicianName, style: const TextStyle(fontSize: 15)),
            const Text(
              "Privacy Protected (Masked Call Active)",
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Masked Calling Button
          IconButton(
            icon: const Icon(Icons.phone_in_talk),
            tooltip: "လုံခြုံစွာ ဖုန်းခေါ်ရန်",
            onPressed: _makeMaskedCall,
          ),
        ],
      ),
      body: Column(
        children: [
          // စာရင်းပြ စာမျက်နှာ (Message List)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isCustomer = msg["sender"] == "customer";
                return Align(
                  alignment: isCustomer
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isCustomer ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg["text"],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg["time"],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // စာရိုက်ထည့်သည့် အောက်ခြေဘား (Message Input Bar)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "စာတို ပေးပို့ရန်...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
