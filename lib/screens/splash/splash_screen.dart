import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  // ⏱️ စက္ကန့် ၃ စက္ကန့် စောင့်ပြီး User အခြေအနေကို စစ်ဆေးကာ လမ်းကြောင်းခွဲရန်
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Firebase Auth ဖြင့် လက်ရှိအကောင့် ဝင်ထားခြင်း ရှိမရှိ စစ်ဆေးခြင်း
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🔓 အကောင့်မဝင်ရသေးပါက Login မျက်နှာပြင်သို့ သွားမည်
      context.go('/login');
    } else {
      // 🔐 အကောင့်ဝင်ထားပြီးသားဖြစ်ပါက Customer Home မျက်နှာပြင်သို့ သွားမည်
      context.go('/customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 83, 235), // သင်ကြိုက်နှစ်သက်သော Theme အရောင်
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo သို့မဟုတ် App Icon
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                size: 55,
                color: Color(0xFF0F4C5C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Phaung Home Repair Service',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'သင့်အိမ်အတွက် ယုံကြည်စိတ်ချရသော ဝန်ဆောင်မှုများ အတွက် အကောင်းဆုံးရွေးချယ်မှု',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}