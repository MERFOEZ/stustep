import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register / Sign up with Email and Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user display name in Firebase Auth
      try {
        await userCredential.user?.updateDisplayName(name.trim());
      } catch (displayNameError) {
        debugPrint('Failed to update display name in Firebase Auth: $displayNameError');
      }

      // Create a user document in Firestore
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        debugPrint('Failed to create user document in Firestore: $firestoreError');
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الدخول عبر Google — على الويب نستخدم signInWithPopup مباشرة
  // لأن google_sign_in_web لا يدعم authenticate() ويرمي UnimplementedError
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final UserCredential userCredential;

      if (kIsWeb) {
        // على الويب: Firebase Auth يتولى OAuth كاملاً عبر نافذة منبثقة
        final googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // على الموبايل: المسار المعتاد عبر google_sign_in SDK
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();
        final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;
      if (user != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (!userDoc.exists) {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'name': user.displayName ?? 'Student',
              'email': user.email?.toLowerCase() ?? '',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (firestoreError) {
          debugPrint('Failed to check/create user document in Firestore during Google Sign In: $firestoreError');
        }
      }

      return userCredential;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('canceled') ||
          errStr.contains('sign_in_canceled') ||
          errStr.contains('abort') ||
          errStr.contains('popup-closed-by-user') ||
          errStr.contains('popup_closed_by_user')) {
        return null;
      }
      rethrow;
    }
  }

  // تسجيل الخروج — على الويب لا حاجة لاستدعاء GoogleSignIn.signOut
  // لأننا استخدمنا signInWithPopup من Firebase مباشرة
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }

  // Fetch user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}

