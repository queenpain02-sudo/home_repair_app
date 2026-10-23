import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register new customer
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    print('REGISTER 1: Creating Firebase Auth account...');

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    print('REGISTER 2: Firebase Auth account created.');

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Unable to create user account.',
      );
    }

    print('REGISTER 3: Updating display name...');

    await user.updateDisplayName(name.trim());

    print('REGISTER 4: Creating Firestore profile...');

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email.trim(),
      'name': name.trim(),
      'displayName': name.trim(),
      'phone': phone.trim(),
      'profileImageUrl': '',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('REGISTER 5: Firestore profile created successfully.');

    return credential;
  }

  /// Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current user's Firestore profile
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return await _firestore.collection('users').doc(user.uid).get();
  }

  /// Password reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
