import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔑 Email နှင့် Password ဖြင့် Login ဝင်သည့် Method
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow; // Error တက်လာပါက LoginScreen ဘက်သို့ ပို့ပေးရန်
    }
  }

  // 📝 Register လုပ်ပြီး Firestore တွင် User Profile အချက်အလက်ပါ သိမ်းဆည်းသည့် Method
  Future<UserCredential> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      // ၁။ Firebase Authentication တွင် အကောင့်အသစ် ဖန်တီးခြင်း
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // ၂။ Firestore ၏ 'users' collection ထဲတွင် အချက်အလက်များနှင့် Role (customer) ထည့်သွင်းခြင်း
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'phone': phone,
          'email': email,
          'role': 'customer', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // 🌐 Google Sign-In ဖြင့် အကောင့်ဝင်ရောက်ခြင်း Method
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User က ပယ်ဖျက်လိုက်လျှင်

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Firestore တွင် ဤ user ၏ profile ရှိမရှိ စစ်ဆေးခြင်း
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // မရှိသေးပါက Google မှ အချက်အလက်များဖြင့် အသစ်ဖန်တီးပေးခြင်း
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? 'Customer',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'profileImage': user.photoURL ?? '',
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In Error: $e');
    }
  }

  // 🔄 Password Reset (စကားဝှက်အသစ်တောင်းခံရန်) လုပ်ဆောင်ချက်
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }
}